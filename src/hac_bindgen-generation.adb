-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Emission rules ([A002]): functions are wrapped (an imported
--  <Op>_Callback with a result slot, a public function calling it);
--  conversions are instantiated per source type mark so the native
--  subtype checks apply; the HAC-side types are mirrored verbatim from
--  the model's mirror text; the registration names are the qualified
--  names of the HAC-side declarations, uppercased by HAC.
-- -----------------------------------------------------------------------------

with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Hac_Bindgen.Generation is

   package M   renames Hac_Bindgen.Model;
   package SU  renames Ada.Strings.Unbounded;
   package TIO renames Ada.Text_IO;

   use SU;
   use type M.Classification_Kind;
   use type M.Declaration_Kind;
   use type M.Parameter_Mode;

   --  How a value of one type crosses the boundary.
   type Conversion_Kind is
     (No_Conversion,     --  procedures have no result
      Direct_Integer,    --  To_HAC / To_Native (standard Integer)
      Direct_Float,      --  To_HAC / To_Native (standard Long_Float)
      Direct_String,     --  To_HAC / To_Native (String, copies both
                         --  ways; [A006])
      Any_Integer_Kind,  --  instantiated pair on the type mark
      Any_Float_Kind,
      Any_Enum_Kind,     --  enumerations, including Boolean
      Handle_Kind);      --  integer handle into the adapter registry
                         --  ([A004])

   type Bound_Parameter is record
      Name        : Unbounded_String;
      Type_Mark   : Unbounded_String;  --  as written in the source
      Mode        : M.Parameter_Mode;
      Kind        : Conversion_Kind;
      Handle_Root : Unbounded_String;  --  Handle_Kind: the handleable
                                       --  root type of the mark
   end record;

   package Bound_Parameter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Bound_Parameter);

   type Bound_Subprogram is record
      Is_Function : Boolean;
      Name        : Unbounded_String;
      Params      : Bound_Parameter_Vectors.Vector;
      Result_Mark : Unbounded_String;
      Result_Root : Unbounded_String;
      --  Handle_Kind result: the handleable root type ([A004]).
      Result_Kind : Conversion_Kind := No_Conversion;
      Synthetic   : Boolean := False;
      --  A generated Drop_<T> operation ([A004]): not part of the
      --  API, its callback releases the registry entry instead of
      --  calling an API subprogram.
   end record;

   package Bound_Subprogram_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Bound_Subprogram);

   type Mirrored_Type is record
      Is_Subtype : Boolean;
      Name       : Unbounded_String;
      Mirror     : Unbounded_String;  --  the declaration text after the name
   end record;

   package Mirrored_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Mirrored_Type);

   package Name_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Unbounded_String);

   type Instantiation is record
      To_HAC : Boolean;
      Kind   : Conversion_Kind;
      Actual : Unbounded_String;  --  qualified actual of the generic
      Name   : Unbounded_String;  --  To_HAC_<Mark> / To_Native_<Mark>
   end record;

   package Instantiation_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Instantiation);

   ---------------------------------------------------------------------
   --  Helpers

   --  How a value of the referenced type crosses the boundary.
   function Conversion_Of (Ref : M.Type_Reference) return Conversion_Kind is
      Root : constant M.Type_Kind :=
        (if Ref.Subtype_Chain.Is_Empty
         then M.Unknown_Type
         else Ref.Subtype_Chain.Last_Element.Kind);
      Mark : constant String := To_String (Ref.Source_Name);
   begin
      case Root is
         when M.Integer_Type =>
            return (if Mark = "Integer"
                    then Direct_Integer else Any_Integer_Kind);
         when M.Floating_Point_Type =>
            return (if Mark = "Long_Float"
                    then Direct_Float else Any_Float_Kind);
         when M.Boolean_Type | M.Enumeration_Type =>
            return Any_Enum_Kind;
         when M.String_Type =>
            --  A string crosses as a copy, both ways ([A006]): the
            --  direct String overloads of To_HAC / To_Native.
            return Direct_String;
         when M.Tagged_Type | M.Private_Type =>
            --  A private partial view crosses as an integer handle
            --  ([A004]); anything else stays a traversal warning.
            if not Ref.Subtype_Chain.Is_Empty
              and then Ref.Subtype_Chain.Last_Element.Handleable
            then
               return Handle_Kind;
            end if;
            raise Generation_Error with
              "internal error: non-scalar type """ & Mark
              & """ reached the generator; the traversal should have"
              & " warned it out";
         when others =>
            raise Generation_Error with
              "internal error: non-scalar type """ & Mark
              & """ reached the generator; the traversal should have"
              & " warned it out";
      end case;
   end Conversion_Of;

   ---------------------------------------------------------------------

   procedure Generate
     (Pkg         : M.Package_Model;
      Result      : M.Analysis_Result;
      Hac_Package : String;
      Output_Dir  : String)
   is
      Hac_Name    : constant String :=
        (if Hac_Package = ""
         then To_String (Pkg.Source_Name)
         else Hac_Package);
      Native_Name : constant String :=
        To_String (Pkg.Source_Name) & "_Native";
      Api_Name    : constant String := To_String (Pkg.Source_Name);

      Bound        : Bound_Subprogram_Vectors.Vector;
      Mirrors      : Mirrored_Type_Vectors.Vector;
      Instanced    : Instantiation_Vectors.Vector;
      Handle_Types : Name_Vectors.Vector;
      --  The handleable root types a bound profile refers to, in
      --  first-use order ([A004]): they drive the handle subtypes,
      --  the Drop operations, the registry instantiations, and the
      --  helper emission.

      Has_Functions : Boolean := False;
      Needs_HAT     : Boolean := False;

      ---------------------------------------------------------------
      --  Text helpers

      --  The type mark as the HAC side spells it: a mirrored local
      --  type keeps its name; a non-mirrorable local type (range,
      --  derived and digits definitions are not supported by HAC)
      --  falls back to its mapped root type - the range checks stay
      --  on the native side, which instantiates on the real type;
      --  standard marks map onto HAC's Integer and Real.
      function HAC_Mark (Mark : String) return String is
      begin
         for Declaration of Pkg.Declarations loop
            if Declaration.Kind = M.Type_Declaration
              and then To_String (Declaration.Source_Name) = Mark
            then
               if Declaration.Mirrorable then
                  return Mark;
               elsif Declaration.Handleable then
                  --  A handleable type crosses as the generated
                  --  handle subtype ([A004]).
                  return Mark & "_Handle";
               else
                  case Declaration.Declared_Kind is
                     when M.Integer_Type =>
                        return "Integer";
                     when M.Floating_Point_Type =>
                        return "Real";
                     when M.Boolean_Type =>
                        return "Boolean";
                     when others =>
                        return Mark;
                  end case;
               end if;
            end if;
         end loop;

         if Mark = "Long_Float"
           or else Mark = "Float"
           or else Mark = "Long_Long_Float"
         then
            return "Real";
         elsif Mark = "String" then
            --  HAC rejects unconstrained String parameters: the HAC
            --  side uses HAT's VString ([A006]); the script builds
            --  one with "+\"...\"".
            return "VString";
         elsif Mark = "Short_Integer"
           or else Mark = "Short_Short_Integer"
           or else Mark = "Long_Integer"
           or else Mark = "Long_Long_Integer"
         then
            return "Integer";
         else
            return Mark;
         end if;
      end HAC_Mark;

      --  A subtype's mirror text with its base type mark mapped the
      --  HAC way: a subtype of a non-mirrorable type is rebased on
      --  the mapped root ("is Small range -10 .. 10" becomes
      --  "is Integer range -10 .. 10").
      function HAC_Mirror (Text : String) return String is
         Base_First : constant Positive := Text'First + 3;
         Base_Last  : Natural := Base_First;
      begin
         while Base_Last < Text'Last
           and then Text (Base_Last + 1) /= ' '
         loop
            Base_Last := Base_Last + 1;
         end loop;
         declare
            Base : constant String := Text (Base_First .. Base_Last);
            Rest : constant String :=
              (if Base_Last < Text'Last
               then Text (Base_Last + 1 .. Text'Last)
               else "");
         begin
            --  A constrained array or string subtype keeps its base
            --  verbatim: the parenthesis constraint syntax belongs
            --  to array types, and VString takes no constraint
            --  ([A006]); only the scalar "range" form remaps its
            --  base ("is Small range ..." becomes
            --  "is Integer range ...").
            return "is "
              & (if Rest'Length > 1
                   and then Rest (Rest'First + 1) = '('
                 then Base
                 else HAC_Mark (Base))
              & Rest;
         end;
      end HAC_Mirror;

      function Mode_Image (Mode : M.Parameter_Mode) return String is
      begin
         case Mode is
            when M.In_Mode =>
               return "in";
            when M.In_Out_Mode =>
               return "in out";
            when M.Out_Mode =>
               return "out";
         end case;
      end Mode_Image;

      --  Same as Param_List, with the marks spelled the HAC way.
      function HAC_Param_List
        (Params : Bound_Parameter_Vectors.Vector) return String
      is
         Buffer : Unbounded_String;
      begin
         for P of Params loop
            if Length (Buffer) > 0 then
               Buffer := Buffer & "; ";
            end if;
            Buffer := Buffer & P.Name & " : " & Mode_Image (P.Mode)
                      & " " & HAC_Mark (To_String (P.Type_Mark));
         end loop;
         if Length (Buffer) = 0 then
            return "";
         else
            return " (" & To_String (Buffer) & ")";
         end if;
      end HAC_Param_List;

      function Callback_Param_List
        (Params      : Bound_Parameter_Vectors.Vector;
         Result_Mark : String) return String
      is
         Buffer : Unbounded_String;
      begin
         if Result_Mark /= "" then
            Buffer := To_Unbounded_String
              ("Result : out " & HAC_Mark (Result_Mark));
         end if;
         for P of Params loop
            if Length (Buffer) > 0 then
               Buffer := Buffer & "; ";
            end if;
            Buffer := Buffer & P.Name & " : " & Mode_Image (P.Mode)
                      & " " & HAC_Mark (To_String (P.Type_Mark));
         end loop;
         return " (" & To_String (Buffer) & ")";
      end Callback_Param_List;

      --  A standard type stands alone; a local one is qualified by
      --  the API package.
      function Qualified (Mark : String) return String is
      begin
         if Mark = "Integer"
           or else Mark = "Long_Float"
           or else Mark = "Boolean"
           or else Mark = "String"
         then
            return Mark;
         else
            return Api_Name & "." & Mark;
         end if;
      end Qualified;

      --  The native type of a bound parameter, for the copy-back
      --  locals.
      function Native_Type_Of (Mark : String) return String is
         (Qualified (Mark));

      function Image (N : Positive) return String is
         S : constant String := N'Image;
      begin
         return S (S'First + 1 .. S'Last);
      end Image;

      --  The GNAT default file naming: the unit name in lower case,
      --  the dots of child units as hyphens. The first profile has no
      --  child units; the rule is handled for completeness.
      function GNAT_File_Naming (Unit_Name : String) return String is
         Buffer : Unbounded_String;
      begin
         for C of Unit_Name loop
            if C = '.' then
               Buffer := Buffer & '-';
            elsif C in 'A' .. 'Z' then
               Buffer := Buffer
                 & Character'Val (Character'Pos (C)
                                  + Character'Pos ('a')
                                  - Character'Pos ('A'));
            else
               Buffer := Buffer & C;
            end if;
         end loop;
         return To_String (Buffer);
      end GNAT_File_Naming;

      --  The expression reading one argument from its Data slot, in
      --  the native type of the parameter.
      function Read_Expression
        (P : Bound_Parameter; Slot : Positive) return String
      is
         Call : constant String := "Data (" & Image (Slot) & ")";
      begin
         case P.Kind is
            when Direct_Integer | Direct_Float | Direct_String =>
               return "To_Native (" & Call & ")";
            when Handle_Kind =>
               --  The registry object the handle designates,
               --  dereferenced ([A004]); an unknown or dropped handle
               --  raises the registry's Unknown_Handle, which
               --  propagates to HAC ([S007]). The qualified
               --  Integer'(...) resolves To_Native's Integer
               --  overload, which the conversion context alone
               --  leaves ambiguous.
               return To_String (P.Handle_Root) & "_Handles.From_Handle ("
                 & To_String (P.Handle_Root) & "_Handles.Handle (Integer'("
                 & "To_Native (" & Call & ")))).all";
            when others =>
               return "To_Native_" & To_String (P.Type_Mark)
                 & " (" & Call & ")";
         end case;
      end Read_Expression;

      --  The expression converting one native value to its HAC
      --  representation. For Handle_Kind, Mark is the handleable root
      --  type name, not the source mark.
      function Write_Expression
        (Kind  : Conversion_Kind;
         Mark  : String;
         Value : String) return String
      is
      begin
         case Kind is
            when Direct_Integer | Direct_Float | Direct_String =>
               return "To_HAC (" & Value & ")";
            when Handle_Kind =>
               return "To_HAC (Integer (" & Mark
                 & "_Handles.To_Handle (" & Value & ")))";
            when others =>
               return "To_HAC_" & Mark & " (" & Value & ")";
         end case;
      end Write_Expression;

      ---------------------------------------------------------------
      --  File output

      function Out_Path (Name : String) return String is
      begin
         if Output_Dir = "" then
            return Name;
         elsif Output_Dir (Output_Dir'Last) = '/'
           or else Output_Dir (Output_Dir'Last) = '\'
         then
            return Output_Dir & Name;
         else
            return Output_Dir & "/" & Name;
         end if;
      end Out_Path;

      procedure Create
        (File : out TIO.File_Type;
         Name : String)
      is
      begin
         if Output_Dir /= ""
           and then not Ada.Directories.Exists (Output_Dir)
         then
            Ada.Directories.Create_Path (Output_Dir);
         end if;
         TIO.Create (File, TIO.Out_File, Out_Path (Name));
      exception
         when E : TIO.Name_Error | TIO.Use_Error =>
            raise Generation_Error with
              "cannot write " & Out_Path (Name) & ": "
              & Ada.Exceptions.Exception_Message (E);
      end Create;

      procedure Put_Header (File : TIO.File_Type) is
      begin
         TIO.Put_Line
           (File,
            "--  Generated by hac-bindgen " & Hac_Bindgen.Version
            & " - do not edit.");
         TIO.New_Line (File);
      end Put_Header;

      ---------------------------------------------------------------
      --  Pass 1: the bound subprograms, from the model and the
      --  classification, in declaration order. The two vectors are
      --  parallel: every declaration has exactly one result.

      procedure Collect_Bound is
         Index : Positive := 1;

         --  Record a handleable root type in first-use order.
         procedure Add_Handle_Type (Root : String) is
         begin
            for Existing of Handle_Types loop
               if To_String (Existing) = Root then
                  return;
               end if;
            end loop;
            Handle_Types.Append (To_Unbounded_String (Root));
         end Add_Handle_Type;

         --  The handleable root of a type reference, for Handle_Kind.
         function Root_Of (Ref : M.Type_Reference) return String is
         begin
            if Ref.Subtype_Chain.Is_Empty then
               return "";
            end if;
            return To_String (Ref.Subtype_Chain.Last_Element.Source_Name);
         end Root_Of;

      begin
         for Declaration of Pkg.Declarations loop
            declare
               Item : constant M.Declaration_Result :=
                 Result.Declarations.Element (Index);
            begin
               if Item.Decision.Kind = M.Bindable
                 and then (Declaration.Kind = M.Procedure_Declaration
                           or else Declaration.Kind
                                    = M.Function_Declaration)
               then
                  declare
                     S : Bound_Subprogram :=
                       (Is_Function =>
                          Declaration.Kind = M.Function_Declaration,
                        Name        => Declaration.Source_Name,
                        Params      => <>,
                        Result_Mark => <>,
                        Result_Root => <>,
                        Result_Kind => No_Conversion,
                        Synthetic   => False);
                  begin
                     for P of Declaration.Parameters loop
                        S.Params.Append
                          (Bound_Parameter'
                             (Name        => P.Source_Name,
                              Type_Mark   => P.Parameter_Type.Source_Name,
                              Mode        => P.Mode,
                              Kind        => Conversion_Of (P.Parameter_Type),
                              Handle_Root =>
                                (if Conversion_Of (P.Parameter_Type)
                                       = Handle_Kind
                                 then To_Unbounded_String
                                        (Root_Of (P.Parameter_Type))
                                 else SU.Null_Unbounded_String)));
                        if S.Params.Last_Element.Kind = Handle_Kind then
                           Add_Handle_Type (Root_Of (P.Parameter_Type));
                        end if;
                     end loop;
                     if S.Is_Function then
                        S.Result_Mark :=
                          Declaration.Result_Type.Source_Name;
                        S.Result_Kind :=
                          Conversion_Of (Declaration.Result_Type);
                        if S.Result_Kind = Handle_Kind then
                           S.Result_Root :=
                             To_Unbounded_String
                               (Root_Of (Declaration.Result_Type));
                           Add_Handle_Type (Root_Of (Declaration.Result_Type));
                        end if;
                     end if;
                     Bound.Append (S);
                  end;
               end if;
            end;
            Index := Index + 1;
         end loop;

         --  One generated Drop_<T> per handleable type, after the API
         --  operations ([A004]): the explicit-ownership operation
         --  that releases the registry entry.
         for T of Handle_Types loop
            declare
               Drop_Op : Bound_Subprogram :=
                 (Is_Function => False,
                  Name        =>
                    To_Unbounded_String ("Drop_" & To_String (T)),
                  Params      => <>,
                  Result_Mark => <>,
                  Result_Root => <>,
                  Result_Kind => No_Conversion,
                  Synthetic   => True);
            begin
               Drop_Op.Params.Append
                 (Bound_Parameter'
                    (Name        => To_Unbounded_String ("W"),
                     Type_Mark   => To_Unbounded_String
                                      (To_String (T) & "_Handle"),
                     Mode        => M.In_Mode,
                     Kind        => Handle_Kind,
                     Handle_Root => T));
               Bound.Append (Drop_Op);
            end;
         end loop;

         for S of Bound loop
            if S.Is_Function then
               Has_Functions := True;
            end if;
            for P of S.Params loop
               if HAC_Mark (To_String (P.Type_Mark))
                    in "Real" | "VString"
               then
                  Needs_HAT := True;
               end if;
            end loop;
            if S.Is_Function
              and then HAC_Mark (To_String (S.Result_Mark))
                         in "Real" | "VString"
            then
               Needs_HAT := True;
            end if;
         end loop;
      end Collect_Bound;

      ---------------------------------------------------------------
      --  Pass 2: the types mirrored on the HAC side: the local type
      --  declarations a bound profile refers to, in declaration
      --  order.

      procedure Collect_Mirrors is

         --  Does a bound profile refer to the declaration, directly
         --  by its mark or through a handle root ([A004])?
         function Referenced_By_Bound (Name : String) return Boolean is
         begin
            for S of Bound loop
               for P of S.Params loop
                  if To_String (P.Type_Mark) = Name
                    or else To_String (P.Handle_Root) = Name
                  then
                     return True;
                  end if;
               end loop;
               if S.Is_Function
                 and then (To_String (S.Result_Mark) = Name
                             or else To_String (S.Result_Root) = Name)
               then
                  return True;
               end if;
            end loop;
            return False;
         end Referenced_By_Bound;

         --  The generated handle subtype of a handleable type
         --  ([A004]): the mirror is "is Integer".
         procedure Collect_Handle_Subtypes is
         begin
            for Declaration of Pkg.Declarations loop
               if Declaration.Kind = M.Type_Declaration
                 and then Declaration.Handleable
                 and then Referenced_By_Bound
                            (To_String (Declaration.Source_Name))
               then
                  Mirrors.Append
                    (Mirrored_Type'
                       (Is_Subtype => True,
                        Name       => To_Unbounded_String
                                        (To_String (Declaration.Source_Name)
                                         & "_Handle"),
                        Mirror     => To_Unbounded_String ("is Integer")));
               end if;
            end loop;
         end Collect_Handle_Subtypes;

      begin
         for Declaration of Pkg.Declarations loop
            if Declaration.Kind = M.Type_Declaration
              and then Declaration.Mirrorable
            then
               declare
                  Referenced : constant Boolean :=
                    Referenced_By_Bound
                      (To_String (Declaration.Source_Name));
               begin
                  if Referenced then
                     Mirrors.Append
                       (Mirrored_Type'
                          (Is_Subtype => Declaration.Is_Subtype,
                           Name       => Declaration.Source_Name,
                           Mirror     =>
                             (if Declaration.Is_Subtype
                              then To_Unbounded_String
                                     (HAC_Mirror
                                        (To_String
                                           (Declaration.Mirror_Text)))
                              else Declaration.Mirror_Text)));
                  end if;
               end;
            end if;
         end loop;

         Collect_Handle_Subtypes;
      end Collect_Mirrors;

      ---------------------------------------------------------------
      --  Pass 3: the conversion instantiations, one per direction and
      --  per type mark, in first-use order.

      procedure Collect_Instantiations is

         procedure Add
           (To_HAC : Boolean;
            Kind   : Conversion_Kind;
            Mark   : String)
         is
            Candidate : constant Instantiation :=
              (To_HAC => To_HAC,
               Kind   => Kind,
               Actual => To_Unbounded_String (Qualified (Mark)),
               Name   => To_Unbounded_String
                           ((if To_HAC then "To_HAC_" else "To_Native_")
                            & Mark));
         begin
            for Existing of Instanced loop
               if Existing.To_HAC = Candidate.To_HAC
                 and then Existing.Name = Candidate.Name
               then
                  return;
               end if;
            end loop;
            Instanced.Append (Candidate);
         end Add;

      begin
         for S of Bound loop
            for P of S.Params loop
               case P.Kind is
                  when Any_Integer_Kind
                    | Any_Float_Kind
                    | Any_Enum_Kind
                  =>
                     --  Each direction is instantiated when actually
                     --  used: an out parameter is never read, an in
                     --  parameter is never written back ([copy-back
                     --  proposal]).
                     if P.Mode /= M.Out_Mode then
                        Add
                          (To_HAC => False,
                           Kind   => P.Kind,
                           Mark   => To_String (P.Type_Mark));
                     end if;
                     if P.Mode /= M.In_Mode then
                        Add
                          (To_HAC => True,
                           Kind   => P.Kind,
                           Mark   => To_String (P.Type_Mark));
                     end if;
                  when others =>
                     null;
               end case;
            end loop;
            if S.Is_Function then
               case S.Result_Kind is
                  when Any_Integer_Kind
                    | Any_Float_Kind
                    | Any_Enum_Kind
                  =>
                     Add
                       (To_HAC => True,
                        Kind   => S.Result_Kind,
                        Mark   => To_String (S.Result_Mark));
                  when others =>
                     null;
               end case;
            end if;
         end loop;
      end Collect_Instantiations;

      ---------------------------------------------------------------
      --  The emitted files.

      procedure Emit_Hac_Spec is
         File       : TIO.File_Type;
         Any_Mirror : Boolean := False;
         Any_Bound  : Boolean := False;
      begin
         for T of Mirrors loop
            Any_Mirror := True;
         end loop;
         for S of Bound loop
            Any_Bound := True;
         end loop;

         Create (File, GNAT_File_Naming (Hac_Name) & ".ads");
         Put_Header (File);
         if Needs_HAT then
            --  HAC's float type is Real, in HAT (not Standard).
            TIO.Put_Line (File, "with HAT; use HAT;");
            TIO.New_Line (File);
         end if;
         TIO.Put_Line (File, "package " & Hac_Name & " is");
         if Any_Mirror or else Any_Bound then
            TIO.New_Line (File);
         end if;

         for T of Mirrors loop
            TIO.Put_Line
              (File,
               "   " & (if T.Is_Subtype then "subtype " else "type ")
               & To_String (T.Name) & " " & To_String (T.Mirror) & ";");
         end loop;
         if Any_Mirror and then Any_Bound then
            TIO.New_Line (File);
         end if;

         for S of Bound loop
            if not S.Is_Function then
               TIO.Put_Line
                 (File,
                  "   procedure " & To_String (S.Name)
                  & HAC_Param_List (S.Params)
                  & " with Import => True;");
            else
               TIO.Put_Line
                 (File,
                  "   function " & To_String (S.Name)
                  & HAC_Param_List (S.Params) & " return "
                  & HAC_Mark (To_String (S.Result_Mark)) & ";");
            end if;
         end loop;

         if Has_Functions then
            TIO.New_Line (File);
            TIO.Put_Line (File, "private");
            TIO.New_Line (File);
            for S of Bound loop
               if S.Is_Function then
                  TIO.Put_Line
                    (File,
                     "   procedure " & To_String (S.Name) & "_Callback");
                  TIO.Put_Line
                    (File,
                     "     "
                     & Callback_Param_List
                         (S.Params, To_String (S.Result_Mark)));
                  TIO.Put_Line (File, "   with Import => True;");
               end if;
            end loop;
         end if;

         TIO.New_Line (File);
         TIO.Put_Line (File, "end " & Hac_Name & ";");
         TIO.Close (File);
      end Emit_Hac_Spec;

      procedure Emit_Hac_Body is
         File : TIO.File_Type;
      begin
         --  HAC requires a package body as soon as the spec declares
         --  subprograms, even when they are all imports: the body is
         --  always emitted (empty when there is no function to wrap).
         Create (File, GNAT_File_Naming (Hac_Name) & ".adb");
         Put_Header (File);
         TIO.Put_Line (File, "package body " & Hac_Name & " is");

         for S of Bound loop
            if S.Is_Function then
               TIO.New_Line (File);
               TIO.Put_Line
                 (File,
                  "   function " & To_String (S.Name)
                  & HAC_Param_List (S.Params) & " return "
                  & HAC_Mark (To_String (S.Result_Mark)) & " is");
               TIO.Put_Line
                 (File,
                  "      Result : "
                  & HAC_Mark (To_String (S.Result_Mark)) & ";");
               TIO.Put_Line (File, "   begin");
               declare
                  Call : Unbounded_String :=
                    To_Unbounded_String
                      (To_String (S.Name) & "_Callback (Result");
               begin
                  for P of S.Params loop
                     Call := Call & ", " & P.Name;
                  end loop;
                  Call := Call & ");";
                  TIO.Put_Line (File, "      " & To_String (Call));
               end;
               TIO.Put_Line (File, "      return Result;");
               TIO.Put_Line (File, "   end " & To_String (S.Name) & ";");
            end if;
         end loop;

         TIO.New_Line (File);
         TIO.Put_Line (File, "end " & Hac_Name & ";");
         TIO.Close (File);
      end Emit_Hac_Body;

      procedure Emit_Native_Spec is
         File : TIO.File_Type;
      begin
         Create (File, GNAT_File_Naming (Native_Name) & ".ads");
         Put_Header (File);
         TIO.Put_Line (File, "with HAC_Sys.Builder;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "package " & Native_Name & " is");
         TIO.New_Line (File);
         TIO.Put_Line
           (File,
            "   procedure Register_All (BD : HAC_Sys.Builder.Build_Data);");
         TIO.New_Line (File);
         TIO.Put_Line (File, "end " & Native_Name & ";");
         TIO.Close (File);
      end Emit_Native_Spec;

      procedure Emit_Native_Body is
         File : TIO.File_Type;
      begin
         Create (File, GNAT_File_Naming (Native_Name) & ".adb");
         Put_Header (File);
         --  No "with HAC_Sys.Builder": the spec already carries it.
         TIO.Put_Line
           (File, "with HAC_Sys.Interfacing; use HAC_Sys.Interfacing;");
         if not Handle_Types.Is_Empty then
            TIO.Put_Line (File, "with Hac_Bindgen_Handles;");
         end if;
         TIO.Put_Line (File, "with " & Api_Name & ";");
         TIO.New_Line (File);
         TIO.Put_Line (File, "package body " & Native_Name & " is");

         if not Handle_Types.Is_Empty then
            TIO.New_Line (File);
            TIO.Put_Line
              (File,
               "   --  Handle registries, one per handleable type");
            TIO.Put_Line (File, "   --  ([A004]).");
            for T of Handle_Types loop
               TIO.Put_Line
                 (File,
                  "   package " & To_String (T) & "_Handles"
                  & " is new Hac_Bindgen_Handles");
               TIO.Put_Line
                 (File,
                  "     (" & Api_Name & "." & To_String (T)
                  & ", """ & To_String (T) & """);");
            end loop;
         end if;

         if not Instanced.Is_Empty then
            TIO.New_Line (File);
            TIO.Put_Line
              (File, "   --  Conversions, one per direction and per");
            TIO.Put_Line (File, "   --  type mark.");
            for I of Instanced loop
               TIO.Put_Line
                 (File,
                  "   function " & To_String (I.Name) & " is new "
                  & (if I.To_HAC then "To_HAC_Any_" else "To_Native_Any_")
                  & (case I.Kind is
                       when Any_Integer_Kind => "Integer",
                       when Any_Float_Kind   => "Float",
                       when others           => "Enum")
                  & " (" & To_String (I.Actual) & ");");
            end loop;
         end if;

         for S of Bound loop
            TIO.New_Line (File);
            declare
               Call : Unbounded_String := Api_Name & "." & S.Name;
               First : Boolean := True;
               Slot  : Positive := (if S.Is_Function then 2 else 1);
               --  The out / in out scalar parameters cross through
               --  native locals ([copy-back]): declared before the
               --  call, written back into their Data slot after.
               Locals : Unbounded_String;
               Writes : Unbounded_String;
            begin
               if not S.Synthetic then
                  for P of S.Params loop
                     declare
                        Name : constant String := To_String (P.Name);
                        Mark : constant String := To_String (P.Type_Mark);
                     begin
                        if First then
                           Call := Call & " (";
                        else
                           Call := Call & ", ";
                        end if;
                        First := False;

                        if P.Mode /= M.In_Mode
                          and then P.Kind /= Handle_Kind
                        then
                           Call := Call & Name;
                           Locals := Locals
                             & "      " & Name & " : "
                             & Native_Type_Of (Mark)
                             & (if P.Mode = M.In_Out_Mode
                                then " := " & Read_Expression (P, Slot)
                                else "")
                             & ";" & ASCII.LF;
                           Writes := Writes
                             & "      Data (" & Image (Slot) & ") := "
                             & Write_Expression (P.Kind, Mark, Name)
                             & ";" & ASCII.LF;
                        else
                           Call := Call & Name & " => "
                                   & Read_Expression (P, Slot);
                        end if;
                     end;
                     Slot := Slot + 1;
                  end loop;
                  if not First then
                     Call := Call & ")";
                  end if;
               end if;

               TIO.Put_Line
                 (File,
                  "   procedure " & To_String (S.Name)
                  & "_Callback (Data : in out HAC_Element_Array) is");
               TIO.Put (File, To_String (Locals));
               TIO.Put_Line (File, "   begin");

               if S.Synthetic then
                  --  The generated Drop_<T> ([A004]): release the
                  --  registry entry; a later use of the handle is the
                  --  Unknown_Handle boundary error.
                  declare
                     Root : constant String :=
                       To_String (S.Params.First_Element.Handle_Root);
                  begin
                     TIO.Put_Line
                       (File,
                        "      " & Root & "_Handles.Drop ("
                        & Root & "_Handles.Handle (Integer'"
                        & "(To_Native (Data (1)))));");
                  end;

               elsif S.Is_Function then
                  TIO.Put_Line
                    (File,
                     "      Data (1) := "
                     & Write_Expression
                         (S.Result_Kind,
                          (if S.Result_Kind = Handle_Kind
                           then To_String (S.Result_Root)
                           else To_String (S.Result_Mark)),
                          To_String (Call))
                     & ";");
               else
                  TIO.Put_Line (File, "      " & To_String (Call) & ";");
               end if;

               TIO.Put (File, To_String (Writes));
               TIO.Put_Line
                 (File,
                  "   end " & To_String (S.Name) & "_Callback;");
            end;
         end loop;

         TIO.New_Line (File);
         TIO.Put_Line (File, "   procedure Register_All");
         TIO.Put_Line (File, "     (BD : HAC_Sys.Builder.Build_Data)");
         TIO.Put_Line (File, "   is");
         TIO.Put_Line (File, "   begin");
         for S of Bound loop
            TIO.Put_Line
              (File,
               "      Register (BD, " & To_String (S.Name)
               & "_Callback'Access, """ & Hac_Name & "."
               & To_String (S.Name)
               & (if S.Is_Function then "_Callback" else "")
               & """);");
         end loop;
         TIO.Put_Line (File, "   end Register_All;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "end " & Native_Name & ";");
         TIO.Close (File);
      end Emit_Native_Body;

      --  The registry helper ([A004]): emitted once per run, when at
      --  least one handleable type is bound; self-contained, withing
      --  nothing but standard library units.
      procedure Emit_Helper is
         File : TIO.File_Type;
      begin
         if Handle_Types.Is_Empty then
            return;
         end if;

         Create (File, GNAT_File_Naming ("Hac_Bindgen_Handles") & ".ads");
         Put_Header (File);
         TIO.Put_Line
           (File,
            "--  The handle registry generic ([A004]): one instance");
         TIO.Put_Line
           (File,
            "--  per handleable type, in the generated native adapter.");
         TIO.New_Line (File);
         TIO.Put_Line (File, "generic");
         TIO.Put_Line (File, "   type Native_Type (<>) is private;");
         TIO.Put_Line (File, "   Debug_Name : String := """";");
         TIO.Put_Line (File, "package Hac_Bindgen_Handles is");
         TIO.New_Line (File);
         TIO.Put_Line
           (File, "   type Handle is new Integer range 1 .. Integer'Last;");
         TIO.Put_Line (File, "   Unknown_Handle : exception;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   type Native_Access is access Native_Type;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   function To_Handle (V : Native_Type) return Handle;");
         TIO.Put_Line (File, "   --  Copy V into the registry, return its fresh handle.");
         TIO.New_Line (File);
         TIO.Put_Line
           (File, "   function From_Handle (H : Handle) return Native_Access;");
         TIO.Put_Line (File, "   --  The registry object designated by H; raises");
         TIO.Put_Line (File, "   --  Unknown_Handle with message ""unknown <Debug_Name>""");
         TIO.Put_Line (File, "   --  handle <N>"" when H is not a live entry.");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   procedure Drop (H : Handle);");
         TIO.Put_Line (File, "   --  Deallocate the registry object and remove the entry;");
         TIO.Put_Line (File, "   --  a later From_Handle of H raises Unknown_Handle.");
         TIO.New_Line (File);
         TIO.Put_Line (File, "end Hac_Bindgen_Handles;");
         TIO.Close (File);

         Create (File, GNAT_File_Naming ("Hac_Bindgen_Handles") & ".adb");
         Put_Header (File);
         TIO.Put_Line (File, "with Ada.Containers.Vectors;");
         TIO.Put_Line (File, "with Ada.Unchecked_Deallocation;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "package body Hac_Bindgen_Handles is");
         TIO.New_Line (File);
         TIO.Put_Line
           (File,
            "   package Registries is new Ada.Containers.Vectors");
         TIO.Put_Line
           (File,
            "     (Index_Type => Handle, Element_Type => Native_Access);");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   Registry : Registries.Vector;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   procedure Free is new Ada.Unchecked_Deallocation");
         TIO.Put_Line (File, "     (Native_Type, Native_Access);");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   --  The trimmed image of a handle: no leading blank.");
         TIO.Put_Line (File, "   function Image (H : Handle) return String is");
         TIO.Put_Line (File, "      S : constant String := Handle'Image (H);");
         TIO.Put_Line (File, "   begin");
         TIO.Put_Line (File, "      return S (S'First + 1 .. S'Last);");
         TIO.Put_Line (File, "   end Image;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   function To_Handle (V : Native_Type) return Handle is");
         TIO.Put_Line (File, "   begin");
         TIO.Put_Line (File, "      Registry.Append (new Native_Type'(V));");
         TIO.Put_Line (File, "      return Registry.Last_Index;");
         TIO.Put_Line (File, "   end To_Handle;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   function From_Handle (H : Handle) return Native_Access is");
         TIO.Put_Line (File, "   begin");
         TIO.Put_Line (File, "      if H <= Registry.Last_Index");
         TIO.Put_Line (File, "        and then Registry.Element (H) /= null");
         TIO.Put_Line (File, "      then");
         TIO.Put_Line (File, "         return Registry.Element (H);");
         TIO.Put_Line (File, "      end if;");
         TIO.Put_Line (File, "      raise Unknown_Handle");
         TIO.Put_Line (File, "        with ""unknown "" & Debug_Name & "" handle """);
         TIO.Put_Line (File, "             & Image (H);");
         TIO.Put_Line (File, "   end From_Handle;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "   procedure Drop (H : Handle) is");
         TIO.Put_Line (File, "   begin");
         TIO.Put_Line (File, "      if H <= Registry.Last_Index");
         TIO.Put_Line (File, "        and then Registry.Element (H) /= null");
         TIO.Put_Line (File, "      then");
         TIO.Put_Line (File, "         declare");
         TIO.Put_Line (File, "            P : Native_Access := Registry.Element (H);");
         TIO.Put_Line (File, "         begin");
         TIO.Put_Line (File, "            Free (P);");
         TIO.Put_Line (File, "            Registry.Replace_Element (H, null);");
         TIO.Put_Line (File, "         end;");
         TIO.Put_Line (File, "         return;");
         TIO.Put_Line (File, "      end if;");
         TIO.Put_Line (File, "      raise Unknown_Handle");
         TIO.Put_Line (File, "        with ""unknown "" & Debug_Name & "" handle """);
         TIO.Put_Line (File, "             & Image (H);");
         TIO.Put_Line (File, "   end Drop;");
         TIO.New_Line (File);
         TIO.Put_Line (File, "end Hac_Bindgen_Handles;");
         TIO.Close (File);
      end Emit_Helper;

   begin
      Collect_Bound;
      Collect_Mirrors;
      Collect_Instantiations;
      Emit_Helper;
      Emit_Hac_Spec;
      Emit_Hac_Body;
      Emit_Native_Spec;
      Emit_Native_Body;
   end Generate;

end Hac_Bindgen.Generation;
