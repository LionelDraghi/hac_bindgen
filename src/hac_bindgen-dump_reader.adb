-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package body Hac_Bindgen.Dump_Reader is

   package M  renames Hac_Bindgen.Model;
   package SU renames Ada.Strings.Unbounded;
   use SU;

   Standard_Prefix : constant String := "standard.";
   Max_Chain_Depth : constant := 100;
   --  Chain recursion cap; Ada forbids circular subtypes, so a deeper
   --  chain can only come from a malformed dump.

   type Line_Array is array (Positive range <>) of SU.Unbounded_String;
   type Token_Array is array (Positive range <>) of SU.Unbounded_String;

   type Section_Kind is (No_Section, Public_Section, Private_Section);

   type Entity_Kind is (Type_Entity, Subtype_Entity);

   type Entity_Info is record
      Name      : SU.Unbounded_String;
      Loc_Image : SU.Unbounded_String;
      --  The loc as written in the dump: the key references resolve to.
      Kind      : Entity_Kind;
      Own_Kind  : M.Type_Kind := M.Unknown_Type;
      --  Type_Entity: the entity own category.
      Base_Name : SU.Unbounded_String;
      Base_Ref  : SU.Unbounded_String;
      --  Subtype_Entity: the base type mark and its resolved identity.
   end record;

   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Entity_Info);

   type Resolved_Type is record
      Chain       : M.Type_Identity_Vectors.Vector;
      Known       : Boolean := False;
      --  The identity points at standard or at an entity of this dump.
      Has_Unknown : Boolean := False;
      --  Some chain link has no known category.
   end record;

   ---------------------------------------------------------------------------
   --  Text helpers
   ---------------------------------------------------------------------------

   function Is_Blank (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT);

   function Is_Blank_Line (Line : String) return Boolean is
     (for all C of Line => Is_Blank (C));

   function Indent_Of (Line : String) return Natural is
   begin
      for I in Line'Range loop
         if not Is_Blank (Line (I)) then
            return I - Line'First;
         end if;
      end loop;
      return Line'Length;
   end Indent_Of;

   function Starts_With (S : String; Prefix : String) return Boolean is
     (S'Length >= Prefix'Length
      and then S (S'First .. S'First + Prefix'Length - 1) = Prefix);

   --  Split on LF, without keeping a trailing empty line for the final
   --  newline; a trailing CR is stripped from each line (CRLF tolerated).
   function Split_Lines (Text : String) return Line_Array is
      Count : Natural := 1;
   begin
      for C of Text loop
         if C = ASCII.LF then
            Count := Count + 1;
         end if;
      end loop;
      if Text'Length > 0 and then Text (Text'Last) = ASCII.LF then
         Count := Count - 1;
      end if;
      Count := Natural'Max (Count, 1);

      declare
         Result : Line_Array (1 .. Count) := [others => SU.Null_Unbounded_String];
         I      : Natural := 0;
         First  : Natural := Text'First;
      begin
         for K in Text'Range loop
            if Text (K) = ASCII.LF then
               I := I + 1;
               if K > First and then Text (K - 1) = ASCII.CR then
                  Result (I) := SU.To_Unbounded_String (Text (First .. K - 2));
               else
                  Result (I) := SU.To_Unbounded_String (Text (First .. K - 1));
               end if;
               First := K + 1;
            end if;
         end loop;

         if First <= Text'Last then
            I := I + 1;
            if Text (Text'Last) = ASCII.CR then
               Result (I) := SU.To_Unbounded_String (Text (First .. Text'Last - 1));
            else
               Result (I) := SU.To_Unbounded_String (Text (First .. Text'Last));
            end if;
         end if;

         return Result;
      end;
   end Split_Lines;

   function Token_Count (Line : String) return Natural is
      Count   : Natural := 0;
      In_Word : Boolean := False;
   begin
      for C of Line loop
         if Is_Blank (C) then
            In_Word := False;
         elsif not In_Word then
            In_Word := True;
            Count   := Count + 1;
         end if;
      end loop;
      return Count;
   end Token_Count;

   --  Split on blank runs, skipping empty tokens.
   function Tokens_Of (Line : String) return Token_Array is
      Count  : constant Natural := Token_Count (Line);
      Result : Token_Array (1 .. Natural'Max (Count, 1)) :=
        (others => SU.Null_Unbounded_String);
      I      : Natural := 0;
      First  : Natural := 0;
   begin
      for K in Line'Range loop
         if Is_Blank (Line (K)) then
            First := 0;
         elsif First = 0 then
            First := K;
         end if;

         if First /= 0
           and then (K = Line'Last or else Is_Blank (Line (K + 1)))
         then
            I := I + 1;
            Result (I) := SU.To_Unbounded_String (Line (First .. K));
            First := 0;
         end if;
      end loop;

      return Result;
   end Tokens_Of;

   function Tok (T : Token_Array; I : Positive) return String is
     (SU.To_String (T (I)));

   --  Parse "<file>:<line>:<col>" from the right, so that <file> may
   --  contain colons.
   function To_Location
     (Image : String; Line_No : Positive) return M.Source_Location
   is
      Last_Colon : Natural := 0;
      Prev_Colon : Natural := 0;
   begin
      for I in reverse Image'Range loop
         if Image (I) = ':' then
            if Last_Colon = 0 then
               Last_Colon := I;
            else
               Prev_Colon := I;
               exit;
            end if;
         end if;
      end loop;

      if Prev_Colon = 0
        or else Prev_Colon = Image'First
        or else Last_Colon - Prev_Colon < 2
        or else Last_Colon = Image'Last
      then
         raise Dump_Error
           with "line" & Line_No'Image & ": invalid location """
           & Image & """";
      end if;

      begin
         return (File_Path => SU.To_Unbounded_String
                               (Image (Image'First .. Prev_Colon - 1)),
                 Line      => Positive'Value
                               (Image (Prev_Colon + 1 .. Last_Colon - 1)),
                 Column    => Positive'Value
                               (Image (Last_Colon + 1 .. Image'Last)));
      exception
         when Constraint_Error =>
            raise Dump_Error
              with "line" & Line_No'Image & ": invalid location """
              & Image & """";
      end;
   end To_Location;

   function Is_Digits (S : String) return Boolean is
   begin
      if S = "" then
         return False;
      end if;

      for C of S loop
         if C not in '0' .. '9' then
            return False;
         end if;
      end loop;
      return True;
   end Is_Digits;

   function Standard_Kind (Name : String) return M.Type_Kind is
   begin
      if Name = "Boolean" then
         return M.Boolean_Type;

      elsif Name = "Integer"
        or else Name = "Short_Integer"
        or else Name = "Short_Short_Integer"
        or else Name = "Long_Integer"
        or else Name = "Long_Long_Integer"
      then
         return M.Integer_Type;

      elsif Name = "Float"
        or else Name = "Long_Float"
        or else Name = "Long_Long_Float"
      then
         return M.Floating_Point_Type;

      elsif Name = "String"
        or else Name = "Wide_String"
        or else Name = "Wide_Wide_String"
      then
         return M.String_Type;

      else
         return M.Other_Type;
      end if;
   end Standard_Kind;

   ---------------------------------------------------------------------------

   function Read (Dump : String) return M.Package_Model is

      Lines : constant Line_Array := Split_Lines (Dump);

      Entities : Entity_Vectors.Vector;

      Model       : M.Package_Model;
      Pkg_Name    : SU.Unbounded_String;
      Next_Id     : M.Declaration_Id := 1;
      Section     : Section_Kind := No_Section;
      Seen_End    : Boolean := False;

      --  The declaration being built: sub-lines (param, returns,
      --  constraint) extend it one level under it, and it enters the
      --  model when the next declaration, section, or end line starts.
      Pending        : M.Public_Declaration;
      Have_Pending   : Boolean := False;
      Pending_Public : Boolean := False;

      use type M.Declaration_Kind;

      ---------------------------------------------------------------------
      procedure Fail (Line_No : Positive; Message : String) is
      begin
         raise Dump_Error with "line" & Line_No'Image & ": " & Message;
      end Fail;

      ---------------------------------------------------------------------
      procedure Expect
        (Condition : Boolean; Line_No : Positive; Message : String) is
      begin
         if not Condition then
            Fail (Line_No, Message);
         end if;
      end Expect;

      ---------------------------------------------------------------------
      procedure Flush_Pending is
      begin
         if Have_Pending and then Pending_Public then
            Model.Declarations.Append (Pending);
         end if;
         Have_Pending := False;
      end Flush_Pending;

      ---------------------------------------------------------------------
      function Lookup (Loc_Image : String) return Natural is
      begin
         for I in 1 .. Entities.Last_Index loop
            if SU.To_String (Entities.Element (I).Loc_Image) = Loc_Image then
               return I;
            end if;
         end loop;
         return 0;
      end Lookup;

      ---------------------------------------------------------------------
      --  Subtype chain of the entity a resolved identity points at,
      --  ordered from the referenced entity to its root type.
      function Chain_Of
        (Ref           : String;
         Fallback_Name : String;
         Depth         : Natural := 0) return Resolved_Type
      is
         use type M.Type_Kind;
      begin
         if Depth > Max_Chain_Depth then
            raise Dump_Error with "cyclic subtype chain";
         end if;

         if Ref = "" or else Ref = "unresolved" then
            return (Chain => <>, Known => False, Has_Unknown => False);

         elsif Starts_With (Ref, Standard_Prefix) then
            declare
               Name   : constant String :=
                 Ref (Ref'First + Standard_Prefix'Length .. Ref'Last);
               Kind   : constant M.Type_Kind := Standard_Kind (Name);
               Result : Resolved_Type;
            begin
               Result.Chain.Append
                 (M.Type_Identity'
                    (Source_Name    => SU.To_Unbounded_String (Name),
                     Canonical_Name => SU.To_Unbounded_String (Ref),
                     Kind           => Kind));
               Result.Known       := True;
               Result.Has_Unknown := False;
               return Result;
            end;

         else
            declare
               Index : constant Natural := Lookup (Ref);
            begin
               if Index = 0 then
                  declare
                     --  The identity points outside this dump: the
                     --  entity is resolved, but its category is not
                     --  known here.
                     Result : Resolved_Type;
                  begin
                     Result.Chain.Append
                       (M.Type_Identity'
                          (Source_Name    => SU.To_Unbounded_String (Fallback_Name),
                           Canonical_Name => SU.To_Unbounded_String (Ref),
                           Kind           => M.Unknown_Type));
                     Result.Known       := False;
                     Result.Has_Unknown := True;
                     return Result;
                  end;
               end if;

               declare
                  E    : constant Entity_Info := Entities.Element (Index);
                  Sub  : Resolved_Type;
                  Self : M.Type_Identity;
                  Result : Resolved_Type;
               begin
                  if E.Kind = Subtype_Entity then
                     Sub := Chain_Of (SU.To_String (E.Base_Ref),
                                      SU.To_String (E.Base_Name),
                                      Depth + 1);
                  end if;

                  Self := (Source_Name    => E.Name,
                           Canonical_Name => Pkg_Name & "." & E.Name,
                           Kind           =>
                             (if E.Kind = Subtype_Entity
                                and then not Sub.Chain.Is_Empty
                              then Sub.Chain.Last_Element.Kind
                              else E.Own_Kind));

                 Result.Chain.Append (Self);
                 Result.Chain.Append (Sub.Chain);
                 Result.Known       := True;
                 Result.Has_Unknown := Self.Kind = M.Unknown_Type
                                       or else Sub.Has_Unknown;
                 return Result;
               end;
            end;
         end if;
      end Chain_Of;

      ---------------------------------------------------------------------
      function Make_Reference
        (Type_Mark : String; Ref : String) return M.Type_Reference
      is
         R      : constant Resolved_Type := Chain_Of (Ref, Type_Mark);
         Result : M.Type_Reference;
      begin
         Result.Source_Name    := SU.To_Unbounded_String (Type_Mark);
         Result.Subtype_Chain  := R.Chain;

         if Ref = "unresolved" or else R.Chain.Is_Empty then
            Result.Resolution     := M.Unresolved;
            Result.Canonical_Name := SU.To_Unbounded_String (Type_Mark);

         elsif R.Known and then not R.Has_Unknown then
            Result.Resolution     := M.Resolved;
            Result.Canonical_Name := R.Chain.First_Element.Canonical_Name;

         else
            Result.Resolution     := M.Partially_Resolved;
            Result.Canonical_Name := R.Chain.First_Element.Canonical_Name;
         end if;

         return Result;
      end Make_Reference;

      ---------------------------------------------------------------------
      procedure Start_Declaration
        (Name     : String;
         Location : M.Source_Location;
         New_Kind : M.Declaration_Kind)
      is
         Id       : constant M.Declaration_Id := Next_Id;
         New_Name : constant Unbounded_String := To_Unbounded_String (Name);
      begin
         Flush_Pending;

         --  The variant aggregates need a static discriminant, so each
         --  kind is built explicitly.
         case New_Kind is
            when M.Procedure_Declaration =>
               Pending := (Kind => M.Procedure_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>);
            when M.Function_Declaration =>
               Pending := (Kind => M.Function_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>,
                           Result_Type => <>);
            when M.Type_Declaration =>
               Pending := (Kind => M.Type_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>,
                           Declared_Kind => M.Unknown_Type);
            when M.Object_Declaration =>
               Pending := (Kind => M.Object_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>,
                           Object_Type => <>);
            when M.Exception_Declaration =>
               Pending := (Kind => M.Exception_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>);
            when M.Package_Declaration =>
               Pending := (Kind => M.Package_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>);
            when M.Renaming_Declaration =>
               Pending := (Kind => M.Renaming_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>);
            when M.Generic_Declaration =>
               Pending := (Kind => M.Generic_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>);
            when M.Other_Declaration =>
               Pending := (Kind => M.Other_Declaration, Id => Id,
                           Source_Name => New_Name,
                           Canonical_Name => New_Name,
                           Location => Location, Parameters => <>);
         end case;
         Have_Pending   := True;
         Pending_Public := Section = Public_Section;
         Next_Id := M.Declaration_Id'Succ (Next_Id);
      end Start_Declaration;

      ---------------------------------------------------------------------
      procedure Expect_Header (Line_No : Positive; Line : String) is
         Tokens : constant Token_Array := Tokens_Of (Line);
      begin
         Expect (Tokens'Length = 4, Line_No,
                 "expected the header line, got """ & Line & """");
         Expect (Tok (Tokens, 1) = "hac-bindgen-backend", Line_No,
                 "not a hac-bindgen-backend header");
         Expect (Tok (Tokens, 3) = "format", Line_No,
                 "not a hac-bindgen-backend header");
         Expect (Tok (Tokens, 4) = "1", Line_No,
                 "unsupported dump format " & Tok (Tokens, 4));
      end Expect_Header;

      ---------------------------------------------------------------------
      procedure Expect_Package (Line_No : Positive; Line : String) is
         Tokens : constant Token_Array := Tokens_Of (Line);
      begin
         Expect (Tokens'Length = 4, Line_No, "expected the package line");
         Expect (Tok (Tokens, 1) = "package", Line_No,
                 "expected the package line");
         Expect (Tok (Tokens, 3) = "loc", Line_No,
                 "expected the package location");

         Pkg_Name             := SU.To_Unbounded_String (Tok (Tokens, 2));
         Model.Source_Name    := Pkg_Name;
         Model.Canonical_Name := Pkg_Name;
         Model.Location       := To_Location (Tok (Tokens, 4), Line_No);
      end Expect_Package;

      ---------------------------------------------------------------------
      procedure Expect_Section (Line_No : Positive; Line : String) is
         Tokens : constant Token_Array := Tokens_Of (Line);
      begin
         declare
            Keyword : constant String := Tok (Tokens, 1);
         begin
            if Keyword = "public" then
               Expect (Tokens'Length = 1, Line_No,
                       "expected a section line, got """ & Line & """");
               Expect (Section = No_Section, Line_No,
                       "duplicate public section");
               Section := Public_Section;

            elsif Keyword = "private" then
               Expect (Tokens'Length = 1, Line_No,
                       "expected a section line, got """ & Line & """");
               Expect (Section = Public_Section, Line_No,
                       "private section before the public one");
               Section := Private_Section;

            elsif Keyword = "end" then
               Expect (Section /= No_Section, Line_No,
                       "end before any section");
               Expect (Tokens'Length = 2, Line_No, "expected the end line");
               Expect (Tok (Tokens, 2) = SU.To_String (Pkg_Name), Line_No,
                       "end line does not match the package name");
               Seen_End := True;
               Flush_Pending;

            else
               Fail (Line_No, "unknown section """ & Keyword & """");
            end if;
         end;
      end Expect_Section;

      ---------------------------------------------------------------------
      procedure Expect_Declaration (Line_No : Positive; Line : String) is
         Tokens      : constant Token_Array := Tokens_Of (Line);
         Kind        : constant String := Tok (Tokens, 1);
         Is_Subprogram : constant Boolean :=
           Kind = "procedure" or else Kind = "function";
      begin
         Expect (Section /= No_Section, Line_No,
                 "declaration outside a section");

         if Is_Subprogram then
            Expect (Tokens'Length = 4, Line_No,
                    "malformed " & Kind & " line");
            Expect (Tok (Tokens, 3) = "loc", Line_No,
                    "malformed " & Kind & " line");
            Start_Declaration
              (Name     => Tok (Tokens, 2),
               Location => To_Location (Tok (Tokens, 4), Line_No),
               New_Kind => (if Kind = "procedure"
                            then M.Procedure_Declaration
                            else M.Function_Declaration));

         elsif Kind = "subtype" then
            Expect (Tokens'Length = 8, Line_No, "malformed subtype line");
            Expect (Tok (Tokens, 3) = "loc"
                      and then Tok (Tokens, 5) = "base"
                      and then Tok (Tokens, 7) = "resolved", Line_No,
                    "malformed subtype line");
            Start_Declaration
              (Name     => Tok (Tokens, 2),
               Location => To_Location (Tok (Tokens, 4), Line_No),
               New_Kind => M.Type_Declaration);
            Entities.Append
              (Entity_Info'
                (Name      => SU.To_Unbounded_String (Tok (Tokens, 2)),
                Loc_Image => SU.To_Unbounded_String (Tok (Tokens, 4)),
                Kind      => Subtype_Entity,
                Own_Kind  => M.Unknown_Type,
                Base_Name => SU.To_Unbounded_String (Tok (Tokens, 6)),
                Base_Ref  => SU.To_Unbounded_String (Tok (Tokens, 8))));

         elsif Kind = "enum" then
            Expect (Tokens'Length >= 5, Line_No, "malformed enum line");
            Expect (Tok (Tokens, 3) = "loc"
                      and then Tok (Tokens, 5) = "literals", Line_No,
                    "malformed enum line");
            Start_Declaration
              (Name     => Tok (Tokens, 2),
               Location => To_Location (Tok (Tokens, 4), Line_No),
               New_Kind => M.Type_Declaration);
            Entities.Append
              (Entity_Info'
                (Name      => SU.To_Unbounded_String (Tok (Tokens, 2)),
                Loc_Image => SU.To_Unbounded_String (Tok (Tokens, 4)),
                Kind      => Type_Entity,
                Own_Kind  => M.Enumeration_Type,
                Base_Name => SU.Null_Unbounded_String,
                Base_Ref  => SU.Null_Unbounded_String));

         elsif Kind = "type" then
            Expect (Tokens'Length >= 5, Line_No, "malformed type line");
            Expect (Tok (Tokens, 3) = "loc"
                      and then Tok (Tokens, 5) = "definition", Line_No,
                    "malformed type line");
            Start_Declaration
              (Name     => Tok (Tokens, 2),
               Location => To_Location (Tok (Tokens, 4), Line_No),
               New_Kind => M.Type_Declaration);
            Entities.Append
              (Entity_Info'
                (Name      => SU.To_Unbounded_String (Tok (Tokens, 2)),
                Loc_Image => SU.To_Unbounded_String (Tok (Tokens, 4)),
                Kind      => Type_Entity,
                Own_Kind  => M.Unknown_Type,
                Base_Name => SU.Null_Unbounded_String,
                Base_Ref  => SU.Null_Unbounded_String));

         elsif Kind = "constant" or else Kind = "variable" then
            Expect (Tokens'Length in 8 | 10, Line_No,
                    "malformed object line");
            Expect (Tok (Tokens, 3) = "loc"
                      and then Tok (Tokens, 5) = "type"
                      and then Tok (Tokens, 7) = "resolved", Line_No,
                    "malformed object line");
            Start_Declaration
              (Name     => Tok (Tokens, 2),
               Location => To_Location (Tok (Tokens, 4), Line_No),
               New_Kind => M.Object_Declaration);
            Pending.Object_Type :=
              Make_Reference (Tok (Tokens, 6), Tok (Tokens, 8));
            if Tokens'Length = 10 then
               --  The static value is format-1 information the model
               --  does not carry yet; checked, not represented.
               Expect (Tok (Tokens, 9) = "value", Line_No,
                       "malformed object line");
            end if;

         elsif Kind = "unhandled" then
            Expect (Tokens'Length = 4, Line_No, "malformed unhandled line");
            Expect (Tok (Tokens, 3) = "loc", Line_No,
                    "malformed unhandled line");
            Start_Declaration
              (Name     => Tok (Tokens, 2),
               Location => To_Location (Tok (Tokens, 4), Line_No),
               New_Kind => M.Other_Declaration);

         else
            Fail (Line_No, "unknown declaration kind """ & Kind & """");
         end if;
      end Expect_Declaration;

      ---------------------------------------------------------------------
      procedure Expect_Sub_Line (Line_No : Positive; Line : String) is
         Tokens : constant Token_Array := Tokens_Of (Line);
         First  : constant String := Tok (Tokens, 1);
      begin
         Expect (Have_Pending, Line_No, "sub-line outside a declaration");

         if First = "param" then
            Expect (Pending.Kind = M.Procedure_Declaration
                      or else Pending.Kind = M.Function_Declaration,
                    Line_No, "parameter outside a subprogram");
            Expect (Tokens'Length >= 10, Line_No, "malformed param line");
            Expect (Tok (Tokens, 3) = "loc", Line_No, "malformed param line");
            Expect (Tok (Tokens, 5) = "mode", Line_No, "malformed param line");

            declare
               Mode : M.Parameter_Mode;
               Next : Positive := 6;
            begin
               if Tok (Tokens, Next) = "in"
                 and then Next < Tokens'Last
                 and then Tok (Tokens, Next + 1) = "out"
               then
                  Mode := M.In_Out_Mode;
                  Next := Next + 2;
               else
                  Mode := (if Tok (Tokens, Next) = "in"
                           then M.In_Mode else M.Out_Mode);
                  Next := Next + 1;
               end if;

               Expect (Tok (Tokens, Next) = "type", Line_No,
                       "malformed param line");
               Expect (Tok (Tokens, Next + 2) = "resolved", Line_No,
                       "malformed param line");

               Pending.Parameters.Append
                 (M.Parameter'
                    (Source_Name    => SU.To_Unbounded_String (Tok (Tokens, 2)),
                     Canonical_Name => SU.To_Unbounded_String (Tok (Tokens, 2)),
                     Mode           => Mode,
                     Parameter_Type => Make_Reference (Tok (Tokens, Next + 1),
                                                        Tok (Tokens, Next + 3)),
                     Location       => To_Location (Tok (Tokens, 4), Line_No)));
            end;

         elsif First = "returns" then
            Expect (Pending.Kind = M.Function_Declaration, Line_No,
                    "returns line outside a function");
            Expect (Tokens'Length = 4, Line_No, "malformed returns line");
            Expect (Tok (Tokens, 3) = "resolved", Line_No,
                    "malformed returns line");

            Pending.Result_Type := Make_Reference (Tok (Tokens, 2),
                                                    Tok (Tokens, 4));

         elsif First = "constraint" then
            Expect (Pending.Kind = M.Type_Declaration, Line_No,
                    "constraint line outside a type declaration");

            if Tokens'Length = 2 then
               Expect (Tok (Tokens, 2) = "(dynamic)", Line_No,
                       "malformed constraint line");
            else
               Expect (Tokens'Length = 4, Line_No, "malformed constraint line");
               Expect (Tok (Tokens, 3) = "..", Line_No,
                       "malformed constraint line");
               Expect (Is_Digits (Tok (Tokens, 2)), Line_No,
                       "malformed constraint line");
               Expect (Is_Digits (Tok (Tokens, 4)), Line_No,
                       "malformed constraint line");
            end if;

         else
            Fail (Line_No, "unknown sub-line """ & First & """");
         end if;
      end Expect_Sub_Line;

   ---------------------------------------------------------------------------

   begin
      if Lines'Length < 3 then
         raise Dump_Error with "truncated dump";
      end if;

      Expect_Header (1, SU.To_String (Lines (1)));
      Expect_Package (2, SU.To_String (Lines (2)));

      for Line_No in 3 .. Lines'Last loop
         declare
            Line   : constant String := SU.To_String (Lines (Line_No));
            Indent : constant Natural := Indent_Of (Line);
         begin
            if Is_Blank_Line (Line) then
               Fail (Line_No, "empty line");
            elsif Indent = 0 then
               Expect_Section (Line_No, Line);
            elsif Indent = 2 then
               Expect_Declaration (Line_No, Line);
            elsif Indent = 4 then
               Expect_Sub_Line (Line_No, Line);
            else
               Fail (Line_No, "unexpected indentation");
            end if;
         end;
      end loop;

      Expect (Seen_End, Lines'Last, "missing end line");
      Flush_Pending;

      return Model;
   end Read;

end Hac_Bindgen.Dump_Reader;
