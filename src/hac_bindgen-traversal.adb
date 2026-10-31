-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Classification rules ([S006], [B001]): each non-bindable
--  declaration is reported with a stable HACBxxxx identifier, a source
--  location, and a reason — the first construct refused is reported,
--  at the location of that construct. Nothing is silently dropped, and
--  nothing here is an error.
-- -----------------------------------------------------------------------------

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Hac_Bindgen.Traversal is

   package M   renames Hac_Bindgen.Model;
   package SU  renames Ada.Strings.Unbounded;
   package TIO renames Ada.Text_IO;

   use SU;
   use type M.Classification_Kind;
   use type M.Declaration_Id;
   use type M.Declaration_Kind;
   use type M.Parameter_Mode;
   use type M.Resolution_State;

   --  The catalogue of the first profile ([B001]). The identifiers are
   --  stable: they never change meaning.
   Overload_Id       : constant String := "HACB0001";
   Operator_Id       : constant String := "HACB0002";
   Access_Id         : constant String := "HACB0003";
   Private_Tagged_Id : constant String := "HACB0004";
   Composite_Id      : constant String := "HACB0005";
   Task_Protected_Id : constant String := "HACB0006";
   Generic_Id        : constant String := "HACB0007";
   Mode_Id           : constant String := "HACB0008";
   Fixed_Modular_Id  : constant String := "HACB0010";
   Exception_Id      : constant String := "HACB0011";
   Renaming_Id       : constant String := "HACB0012";
   Unresolved_Id     : constant String := "HACB0013";
   Address_Id        : constant String := "HACB0014";
   Not_Covered_Id    : constant String := "HACB0016";
   Char_Literal_Id   : constant String := "HACB0017";

   --  Why a construct cannot be bound, without its location: several
   --  checks share the same wording.
   type Diagnosis is record
      Id     : SU.Unbounded_String;
      Reason : SU.Unbounded_String;
   end record;

   function No_Diagnosis return Diagnosis is
     (others => SU.Null_Unbounded_String);

   function Has_Diagnosis (D : Diagnosis) return Boolean is
     (SU.Length (D.Id) > 0);

   function Diagnose (Id, Reason : String) return Diagnosis is
     (Id     => SU.To_Unbounded_String (Id),
      Reason => SU.To_Unbounded_String (Reason));

   --  A warning attached to one construct at one location.
   type Warning is record
      Id        : SU.Unbounded_String;
      Construct : SU.Unbounded_String;
      Reason    : SU.Unbounded_String;
      Location  : M.Source_Location;
   end record;

   function No_Warning return Warning is
     (Id        => SU.Null_Unbounded_String,
      Construct => SU.Null_Unbounded_String,
      Reason    => SU.Null_Unbounded_String,
      Location  => (File_Path => SU.Null_Unbounded_String,
                    Line      => 1,
                    Column    => 1));

   function Is_Warned (W : Warning) return Boolean is
     (SU.Length (W.Id) > 0);

   function Warn
     (D         : Diagnosis;
      Construct : String;
      Location  : M.Source_Location) return Warning
   is
     (Id        => D.Id,
      Construct => SU.To_Unbounded_String (Construct),
      Reason    => D.Reason,
      Location  => Location);

   ---------------------------------------------------------------------
   --  Text helpers

   function Contains (S : String; Pattern : String) return Boolean is
     (S'Length >= Pattern'Length
      and then (for some I in S'First .. S'Last - Pattern'Length + 1 =>
                  S (I .. I + Pattern'Length - 1) = Pattern));

   function Trim (S : String) return String is
      First : Positive := S'First;
   begin
      while First <= S'Last and then S (First) = ' ' loop
         First := First + 1;
      end loop;
      return S (First .. S'Last);
   end Trim;

   function Image (Loc : M.Source_Location) return String is
     (SU.To_String (Loc.File_Path)
      & ":" & Trim (Loc.Line'Image)
      & ":" & Trim (Loc.Column'Image));

   ---------------------------------------------------------------------
   --  Classification of a type used as a boundary value, from the root
   --  of its subtype chain.

   function Boundary_Diagnosis (Ref : M.Type_Reference) return Diagnosis is
      Mark : constant String := To_String (Ref.Source_Name);
   begin
      --  A class-wide type mark never crosses the boundary, even when
      --  its root is handleable: the profile would need dispatching.
      if Mark'Length > 6
        and then Mark (Mark'Last - 5 .. Mark'Last) = "'Class"
      then
         return Diagnose
           (Private_Tagged_Id,
            "the tool does not own object representation");
      end if;

      if Mark = "System.Address" then
         return Diagnose
           (Address_Id,
            "unchecked address conversions have no defined VM semantics");
      end if;

      if Ref.Resolution = M.Unresolved
        or else Ref.Subtype_Chain.Is_Empty
      then
         return Diagnose
           (Unresolved_Id,
            "the analyser cannot resolve this type to a known category");
      end if;

      case Ref.Subtype_Chain.Last_Element.Kind is
         when M.Enumeration_Type =>
            --  A character-literal enumeration cannot be mirrored:
            --  HAC rejects the declaration ([A005], HACB0017).
            if Ref.Subtype_Chain.Last_Element.Has_Character_Literals then
               return Diagnose
                 (Char_Literal_Id,
                  "HAC only accepts identifier literals");
            end if;
            return No_Diagnosis;

         when M.Integer_Type
            | M.Floating_Point_Type
            | M.Boolean_Type
         =>
            return No_Diagnosis;

         when M.Access_Type =>
            return Diagnose
              (Access_Id,
               "no pointer representation across the VM boundary");

         when M.Array_Type
            | M.Record_Type
            | M.String_Type
         =>
            return Diagnose
              (Composite_Id,
               "composite mapping is deferred to a later profile");

         when M.Tagged_Type
            | M.Private_Type
         =>
            --  A private partial view (not limited, not abstract)
            --  crosses as an integer handle ([A004]); the rest keeps
            --  the object-representation warning.
            if Ref.Subtype_Chain.Last_Element.Handleable then
               return No_Diagnosis;
            end if;
            return Diagnose
              (Private_Tagged_Id,
               "the tool does not own object representation");

         when M.Fixed_Point_Type
            | M.Modular_Type
         =>
            return Diagnose
              (Fixed_Modular_Id,
               "conversion semantics is not demonstrated yet");

         when M.Task_Type
            | M.Protected_Type
         =>
            return Diagnose (Task_Protected_Id, "no VM representation");

         when M.Unknown_Type
            | M.Other_Type
         =>
            return Diagnose
              (Unresolved_Id,
               "the analyser cannot resolve this type to a known category");
      end case;
   end Boundary_Diagnosis;

   ---------------------------------------------------------------------
   --  Classification of a declaration the backend could not represent:
   --  the dump carried the parser kind name. The user-facing construct
   --  name is not the parser kind name: that one is for the dump.

   type Unhandled_Classification is record
      D         : Diagnosis;
      Construct : SU.Unbounded_String;
   end record;

   function Classify_Unhandled
     (Kind_Name : String) return Unhandled_Classification
   is
   begin
      if Contains (Kind_Name, "Exception") then
         return
           (D         =>
              Diagnose
                (Exception_Id,
                 "Ada exception identity does not cross the boundary"),
            Construct => To_Unbounded_String ("exception declaration"));

      elsif Contains (Kind_Name, "Generic")
        and then Contains (Kind_Name, "Package")
      then
         return
           (D         =>
              Diagnose
                (Generic_Id, "instantiate natively, and bind the instance"),
            Construct => To_Unbounded_String ("generic package"));

      elsif Contains (Kind_Name, "Generic") then
         return
           (D         =>
              Diagnose
                (Generic_Id, "instantiate natively, and bind the instance"),
            Construct => To_Unbounded_String ("generic subprogram"));

      elsif Contains (Kind_Name, "Task") then
         return
           (D         => Diagnose (Task_Protected_Id, "no VM representation"),
            Construct => To_Unbounded_String ("task declaration"));

      elsif Contains (Kind_Name, "Protected") then
         return
           (D         => Diagnose (Task_Protected_Id, "no VM representation"),
            Construct => To_Unbounded_String ("protected declaration"));

      elsif Contains (Kind_Name, "Renaming") then
         return
           (D         =>
              Diagnose (Renaming_Id, "declare a regular wrapper instead"),
            Construct => To_Unbounded_String ("renaming declaration"));

      else
         return
           (D         =>
              Diagnose
                (Not_Covered_Id,
                 "not covered by the current binding profile"),
            Construct => To_Unbounded_String (Kind_Name));
      end if;
   end Classify_Unhandled;

   ---------------------------------------------------------------------
   --  Subprogram names already seen, for the overload rule: the first
   --  declaration of a name is bound, the following ones are warned.

   package Name_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => SU.Unbounded_String);

   function Seen (Names : Name_Vectors.Vector; Name : String) return Boolean is
   begin
      for N of Names loop
         if SU.To_String (N) = Name then
            return True;
         end if;
      end loop;
      return False;
   end Seen;

   ---------------------------------------------------------------------

   --  Classification of one subprogram declaration: operator symbols
   --  and overloads are refused at the declaration, parameters and the
   --  result at their own location. The name is recorded as seen,
   --  whether the declaration is bound or not.
   function Classify_Subprogram
     (Declaration : M.Public_Declaration;
      Seen_Names  : in out Name_Vectors.Vector) return Warning
   is
      Name : constant String :=
        SU.To_String (Declaration.Source_Name);
      Kind_Word : constant String :=
        (if Declaration.Kind = M.Procedure_Declaration
         then "procedure" else "function");
   begin
      if Name'Length > 0
        and then Name (Name'First) = '"'
      then
         return Warn
           (Diagnose
              (Operator_Id,
               "an operator symbol is not a valid callback name"),
            "operator symbol " & Name,
            Declaration.Location);
      end if;

      if Seen (Seen_Names, Name) then
         return Warn
           (Diagnose
              (Overload_Id,
               "the name " & Name & " is already bound:"
               & " HAC callbacks are keyed by a single name"),
            Kind_Word & " " & Name,
            Declaration.Location);
      end if;

      declare
         W : Warning := No_Warning;
      begin
         for Item of Declaration.Parameters loop
            declare
               D : constant Diagnosis :=
                 Boundary_Diagnosis (Item.Parameter_Type);
               Handleable : constant Boolean :=
                 not Item.Parameter_Type.Subtype_Chain.Is_Empty
                 and then Item.Parameter_Type.Subtype_Chain
                            .Last_Element.Handleable;
            begin
               if Has_Diagnosis (D) then
                  W := Warn
                    (D,
                     "parameter " & SU.To_String (Item.Source_Name),
                     Item.Location);
                  exit;
               end if;

               if Item.Mode /= M.In_Mode then
                  if Declaration.Kind = M.Function_Declaration then
                     --  HAC's functions have in-only parameters
                     --  (verified: the declaration is a parse error).
                     W := Warn
                       (Diagnose
                          (Mode_Id,
                           "HAC functions have in-only parameters"),
                        "parameter " & SU.To_String (Item.Source_Name),
                        Item.Location);
                     exit;
                  elsif Item.Mode = M.Out_Mode
                    and then Handleable
                  then
                     --  A fresh out value would need an uninitialized
                     --  native object, which an indefinite full view
                     --  forbids ([copy-back proposal]).
                     W := Warn
                       (Diagnose
                          (Mode_Id,
                           "the callback cannot default-construct"
                           & " the native object"),
                        "parameter " & SU.To_String (Item.Source_Name),
                        Item.Location);
                     exit;
                  end if;
                  --  A procedure's scalar out / in out, and a
                  --  handleable in out (the registry object passed in
                  --  place): bound with copy-back.
               end if;
            end;
         end loop;

         if not Is_Warned (W)
           and then Declaration.Kind = M.Function_Declaration
         then
            declare
               D : constant Diagnosis :=
                 Boundary_Diagnosis (Declaration.Result_Type);
            begin
               if Has_Diagnosis (D) then
                  W := Warn (D, "function " & Name, Declaration.Location);
               end if;
            end;
         end if;

         Seen_Names.Append (SU.To_Unbounded_String (Name));
         return W;
      end;
   end Classify_Subprogram;

   ---------------------------------------------------------------------

   function Classify
     (Pkg : M.Package_Model) return M.Analysis_Result
   is
      Result     : M.Analysis_Result;
      Seen_Names : Name_Vectors.Vector;

      --  Append the classification of one declaration. The result
      --  covers every declaration of the model, exactly once.
      procedure Add
        (Declaration : M.Public_Declaration;
         W           : Warning)
      is
      begin
         if Is_Warned (W) then
            Result.Declarations.Append
              (M.Declaration_Result'
                 (Declaration => Declaration.Id,
                  Decision    =>
                    (Kind       => M.Not_Bindable,
                     Warning_Id => W.Id,
                     Reason     => W.Reason,
                     Construct  => W.Construct,
                     Location   => W.Location)));
         else
            Result.Declarations.Append
              (M.Declaration_Result'
                 (Declaration => Declaration.Id,
                  Decision    => (Kind => M.Bindable)));
         end if;
      end Add;

   begin
      for Declaration of Pkg.Declarations loop
         declare
            W : Warning := No_Warning;
         begin
            case Declaration.Kind is
               when M.Procedure_Declaration
                  | M.Function_Declaration
               =>
                  W := Classify_Subprogram (Declaration, Seen_Names);

               when M.Type_Declaration =>
                  case Declaration.Declared_Kind is
                     when M.Access_Type =>
                        W := Warn
                          (Diagnose
                             (Access_Id,
                              "no pointer representation across the VM"
                              & " boundary"),
                           "type " & SU.To_String (Declaration.Source_Name),
                           Declaration.Location);
                     when M.Enumeration_Type =>
                        --  A character literal is the only literal shape
                        --  carrying a quote character in the mirror text
                        --  ("is ('0', '1', ...)").
                        if Contains
                             (SU.To_String (Declaration.Mirror_Text), "'")
                        then
                           W := Warn
                             (Diagnose
                                (Char_Literal_Id,
                                 "HAC only accepts identifier literals"),
                              "type "
                              & SU.To_String (Declaration.Source_Name),
                              Declaration.Location);
                        end if;
                     when M.Task_Type | M.Protected_Type =>
                        W := Warn
                          (Diagnose (Task_Protected_Id,
                                     "no VM representation"),
                           "type " & SU.To_String (Declaration.Source_Name),
                           Declaration.Location);
                     when others =>
                        null;  --  warned only as a boundary value
                  end case;

               when M.Object_Declaration =>
                  --  The M2 evidence demonstrates no variable or
                  --  constant mechanism across the boundary: objects
                  --  are not bound by this profile.
                  W := Warn
                    (Diagnose
                       (Not_Covered_Id,
                        "object declarations are not bound by the current"
                        & " binding profile"),
                     SU.To_String (Declaration.Source_Name),
                     Declaration.Location);

               when M.Other_Declaration =>
                  declare
                     U : constant Unhandled_Classification :=
                       Classify_Unhandled
                         (SU.To_String (Declaration.Kind_Name));
                  begin
                     W := Warn
                       (U.D,
                        SU.To_String (U.Construct),
                        Declaration.Location);
                  end;

               when others =>
                  null;
            end case;

            Add (Declaration, W);
         end;
      end loop;

      M.Validate_Analysis (Pkg, Result);
      return Result;
   end Classify;

   ---------------------------------------------------------------------

   function Is_Operation
     (Pkg : M.Package_Model; Id : M.Declaration_Id) return Boolean is
   begin
      for Declaration of Pkg.Declarations loop
         if Declaration.Id = Id then
            return Declaration.Kind = M.Procedure_Declaration
                   or else Declaration.Kind = M.Function_Declaration;
         end if;
      end loop;
      return False;
   end Is_Operation;

   ---------------------------------------------------------------------

   procedure Report
     (Pkg    : M.Package_Model;
      Result : M.Analysis_Result)
   is
      Bound     : Natural := 0;
      Not_Bound : Natural := 0;
      Warnings  : Natural := 0;
   begin
      for Item of Result.Declarations loop
         if Item.Decision.Kind = M.Not_Bindable then
            Warnings := Warnings + 1;
            TIO.Put_Line
              (Image (Item.Decision.Location)
               & ": warning " & SU.To_String (Item.Decision.Warning_Id)
               & ": " & SU.To_String (Item.Decision.Construct)
               & " is not bound: " & SU.To_String (Item.Decision.Reason));
         end if;
      end loop;

      for Item of Result.Declarations loop
         if Is_Operation (Pkg, Item.Declaration) then
            if Item.Decision.Kind = M.Not_Bindable then
               Not_Bound := Not_Bound + 1;
            else
               Bound := Bound + 1;
            end if;
         end if;
      end loop;

      TIO.Put_Line
        (SU.To_String (Pkg.Source_Name) & ": "
         & Trim (Bound'Image) & " operation"
         & (if Bound = 1 then "" else "s")
         & " bound, " & Trim (Not_Bound'Image) & " not bound"
         & (if Warnings > 0 then " (see warnings)" else ""));
   end Report;

end Hac_Bindgen.Traversal;
