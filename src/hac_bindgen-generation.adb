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

   --  How a value of one type crosses the boundary.
   type Conversion_Kind is
     (No_Conversion,     --  procedures have no result
      Direct_Integer,    --  To_HAC / To_Native (standard Integer)
      Direct_Float,      --  To_HAC / To_Native (standard Long_Float)
      Any_Integer_Kind,  --  instantiated pair on the type mark
      Any_Float_Kind,
      Any_Enum_Kind);    --  enumerations, including Boolean

   type Bound_Parameter is record
      Name      : Unbounded_String;
      Type_Mark : Unbounded_String;  --  as written in the source
      Kind      : Conversion_Kind;
   end record;

   package Bound_Parameter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Bound_Parameter);

   type Bound_Subprogram is record
      Is_Function : Boolean;
      Name        : Unbounded_String;
      Params      : Bound_Parameter_Vectors.Vector;
      Result_Mark : Unbounded_String;
      Result_Kind : Conversion_Kind := No_Conversion;
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

      Bound     : Bound_Subprogram_Vectors.Vector;
      Mirrors   : Mirrored_Type_Vectors.Vector;
      Instanced : Instantiation_Vectors.Vector;

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
            return "is " & HAC_Mark (Base) & Rest;
         end;
      end HAC_Mirror;

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
            Buffer := Buffer & P.Name & " : in "
                      & HAC_Mark (To_String (P.Type_Mark));
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
            Buffer := To_Unbounded_String ("Result : out " & Result_Mark);
         end if;
         for P of Params loop
            if Length (Buffer) > 0 then
               Buffer := Buffer & "; ";
            end if;
            Buffer := Buffer & P.Name & " : in " & P.Type_Mark;
         end loop;
         return " (" & To_String (Buffer) & ")";
      end Callback_Param_List;

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
            when Direct_Integer | Direct_Float =>
               return "To_Native (" & Call & ")";
            when others =>
               return "To_Native_" & To_String (P.Type_Mark)
                 & " (" & Call & ")";
         end case;
      end Read_Expression;

      --  The expression converting one native value to its HAC
      --  representation.
      function Write_Expression
        (Kind  : Conversion_Kind;
         Mark  : String;
         Value : String) return String
      is
      begin
         case Kind is
            when Direct_Integer | Direct_Float =>
               return "To_HAC (" & Value & ")";
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
                        Result_Kind => No_Conversion);
                  begin
                     for P of Declaration.Parameters loop
                        S.Params.Append
                          (Bound_Parameter'
                             (Name      => P.Source_Name,
                              Type_Mark => P.Parameter_Type.Source_Name,
                              Kind      =>
                                Conversion_Of (P.Parameter_Type)));
                     end loop;
                     if S.Is_Function then
                        S.Result_Mark :=
                          Declaration.Result_Type.Source_Name;
                        S.Result_Kind :=
                          Conversion_Of (Declaration.Result_Type);
                     end if;
                     Bound.Append (S);
                  end;
               end if;
            end;
            Index := Index + 1;
         end loop;

         for S of Bound loop
            if S.Is_Function then
               Has_Functions := True;
            end if;
            for P of S.Params loop
               if HAC_Mark (To_String (P.Type_Mark)) = "Real" then
                  Needs_HAT := True;
               end if;
            end loop;
            if S.Is_Function
              and then HAC_Mark (To_String (S.Result_Mark)) = "Real"
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
      begin
         for Declaration of Pkg.Declarations loop
            if Declaration.Kind = M.Type_Declaration
              and then Declaration.Mirrorable
            then
               declare
                  Referenced : Boolean := False;
               begin
                  for S of Bound loop
                     for P of S.Params loop
                        if To_String (P.Type_Mark)
                             = To_String (Declaration.Source_Name)
                        then
                           Referenced := True;
                        end if;
                     end loop;
                     if S.Is_Function
                       and then To_String (S.Result_Mark)
                                  = To_String (Declaration.Source_Name)
                     then
                        Referenced := True;
                     end if;
                  end loop;

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
      end Collect_Mirrors;

      ---------------------------------------------------------------
      --  Pass 3: the conversion instantiations, one per direction and
      --  per type mark, in first-use order.

      procedure Collect_Instantiations is

         function Qualified (Mark : String) return String is
         begin
            --  A standard type stands alone; a local one is qualified
            --  by the API package.
            if Mark = "Integer"
              or else Mark = "Long_Float"
              or else Mark = "Boolean"
            then
               return Mark;
            else
               return Api_Name & "." & Mark;
            end if;
         end Qualified;

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
                     Add
                       (To_HAC => False,
                        Kind   => P.Kind,
                        Mark   => To_String (P.Type_Mark));
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
         TIO.Put_Line (File, "with " & Api_Name & ";");
         TIO.New_Line (File);
         TIO.Put_Line (File, "package body " & Native_Name & " is");

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
            TIO.Put_Line
              (File,
               "   procedure " & To_String (S.Name)
               & "_Callback (Data : in out HAC_Element_Array) is");
            TIO.Put_Line (File, "   begin");
            declare
               Call  : Unbounded_String :=
                 Api_Name & "." & S.Name & " (";
               First : Boolean := True;
               --  A function writes its result into slot 1; the
               --  arguments follow ([A002], callback layout).
               Slot  : Positive := (if S.Is_Function then 2 else 1);
            begin
               for P of S.Params loop
                  if not First then
                     Call := Call & ", ";
                  end if;
                  First := False;
                  Call := Call & To_String (P.Name) & " => "
                          & Read_Expression (P, Slot);
                  Slot := Slot + 1;
               end loop;
               Call := Call & ")";

               if S.Is_Function then
                  TIO.Put_Line
                    (File,
                     "      Data (1) := "
                     & Write_Expression
                         (S.Result_Kind,
                          To_String (S.Result_Mark),
                          To_String (Call))
                     & ";");
               else
                  TIO.Put_Line (File, "      " & To_String (Call) & ";");
               end if;
            end;
            TIO.Put_Line
              (File,
               "   end " & To_String (S.Name) & "_Callback;");
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

   begin
      Collect_Bound;
      Collect_Mirrors;
      Collect_Instantiations;
      Emit_Hac_Spec;
      Emit_Hac_Body;
      Emit_Native_Spec;
      Emit_Native_Body;
   end Generate;

end Hac_Bindgen.Generation;
