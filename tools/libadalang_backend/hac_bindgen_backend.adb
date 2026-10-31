--  hac_bindgen_backend -- Libadalang analysis backend for hac_bindgen.
--
--  Parses one Ada package specification and writes the format-1
--  interchange dump specified in docs/features/A003_interchange_dump.md.
--  The main hac_bindgen crate (GNAT 16) never links Libadalang; this
--  dump is the only coupling between the two crates.
--
--  Exit status: 0 on success, 1 when the input cannot be parsed (no
--  dump is produced, diagnostics go to standard error), 2 on usage
--  error.

with Ada.Command_Line;             use Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;                  use Ada.Text_IO;
with GNATCOLL.GMP.Integers;        use GNATCOLL.GMP.Integers;
with Langkit_Support.Slocs;
with Langkit_Support.Text;
with Libadalang.Analysis;
with Libadalang.Common;
with Libadalang.Expr_Eval;
with Hac_Bindgen_Backend_Config;

procedure Hac_Bindgen_Backend is
   package LAL renames Libadalang.Analysis;
   package LCL renames Libadalang.Common;
   package LEE renames Libadalang.Expr_Eval;
   package LSS renames Langkit_Support.Slocs;
   package LST renames Langkit_Support.Text;

   use type LCL.Ada_Node_Kind_Type;

   Format_Version : constant String := "1";

   Input_File : constant String :=
     (if Argument_Count = 1 then Argument (1) else "");

   --  Source text of a node, as UTF-8.
   function Txt (Node : LAL.Ada_Node'Class) return String is
   begin
      if Node.Is_Null then
         return "";
      end if;
      return LST.Encode (LAL.Text (Node), "utf-8");
   end Txt;

   function Trim (S : String) return String is
      First : Natural := S'First;
      Last  : Natural := S'Last;
   begin
      while First <= Last and then S (First) = ' ' loop
         First := First + 1;
      end loop;
      while Last >= First and then S (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      return S (First .. Last);
   end Trim;

   --  Image of a node location as file:line:col, with the file exactly
   --  as supplied on the command line.
   function Loc_Of (Node : LAL.Ada_Node'Class) return String is
      SR : constant LSS.Source_Location_Range := LAL.Sloc_Range (Node);
   begin
      return Input_File & ":" & Trim (SR.Start_Line'Image)
        & ":" & Trim (SR.Start_Column'Image);
   end Loc_Of;

   function Basename (Path : String) return String is
   begin
      for I in reverse Path'Range loop
         if Path (I) = '/' then
            return Path (I + 1 .. Path'Last);
         end if;
      end loop;
      return Path;
   end Basename;

   --  Resolution identity of the declaration a Name refers to:
   --  standard.<Name> for a predefined entity, file:line:col for a
   --  declared entity, "unresolved" otherwise. Never silently mapped
   --  to anything ([S003], parser-independent model contract).
   function Identity_Of (N : LAL.Name'Class) return String is
      Decl : LAL.Basic_Decl;
   begin
      if N.Is_Null then
         return "unresolved";
      end if;
      begin
         Decl := N.P_Referenced_Decl;
      exception
         when LCL.Property_Error =>
            return "unresolved";
      end;
      if Decl.Is_Null or else Decl.P_Defining_Name.Is_Null then
         return "unresolved";
      end if;
      declare
         DN   : constant LAL.Defining_Name := Decl.P_Defining_Name;
         File : constant String := LAL.Get_Filename (Decl.Unit);
      begin
         if Basename (File) = "__standard" then
            return "standard." & Txt (DN);
         else
            return Loc_Of (DN);
         end if;
      end;
   end Identity_Of;

   --  Statically evaluated integer value of an expression, or
   --  "(dynamic)" when it is not statically evaluable.
   function Static_Int (E : LAL.Expr'Class) return String is
      R : constant LEE.Eval_Result := LEE.Expr_Eval (E.As_Expr);
   begin
      case R.Kind is
         when LEE.Int =>
            return Image (R.Int_Result);
         when others =>
            return "(dynamic)";
      end case;
   exception
      when LCL.Property_Error =>
         return "(dynamic)";
   end Static_Int;

   function Mode_Image (M : LAL.Mode) return String is
   begin
      case M.Kind is
         when LCL.Ada_Mode_In      => return "in";
         when LCL.Ada_Mode_In_Out  => return "in out";
         when LCL.Ada_Mode_Out     => return "out";
         when LCL.Ada_Mode_Default => return "in";
         when others               => return "?";
      end case;
   end Mode_Image;

   --  Source text with runs of whitespace collapsed to single spaces,
   --  so that one declaration stays on one dump line.
   function Flatten (S : String) return String is
      Result         : String (S'Range);
      Last           : Natural := Result'First - 1;
      Last_Was_Space : Boolean := False;
   begin
      for C of S loop
         if C = ' '
           or else C = ASCII.HT
           or else C = ASCII.CR
           or else C = ASCII.LF
         then
            if not Last_Was_Space and then Last >= Result'First then
               Last := Last + 1;
               Result (Last) := ' ';
            end if;
            Last_Was_Space := True;
         else
            Last := Last + 1;
            Result (Last) := C;
            Last_Was_Space := False;
         end if;
      end loop;

      if Last >= Result'First and then Result (Last) = ' ' then
         Last := Last - 1;
      end if;
      return Result (Result'First .. Last);
   end Flatten;

   --  Resolution identity of a type expression: the type mark's name
   --  when the expression is a subtype indication, "unresolved"
   --  otherwise.
   function Type_Identity (TE : LAL.Type_Expr'Class) return String is
      SI : constant LAL.Subtype_Indication := TE.As_Subtype_Indication;
   begin
      if SI.Is_Null then
         return "unresolved";
      end if;
      return Identity_Of (SI.F_Name);
   end Type_Identity;

   procedure Put_Decl (Decl : LAL.Basic_Decl'Class) is
      Name : constant String :=
        (if Decl.Is_Null then "" else Txt (Decl.P_Defining_Name));
      Loc  : constant String :=
        (if Decl.Is_Null
         then ""
         elsif Decl.P_Defining_Name.Is_Null
         then Loc_Of (Decl)
         else Loc_Of (Decl.P_Defining_Name));
   begin
      if Decl.Is_Null then
         --  Not a basic declaration (pragma, use clause, ...): not part
         --  of the API model, skipped without a dump line.
         return;
      end if;

      if Decl.Kind in LCL.Ada_Subp_Decl | LCL.Ada_Null_Subp_Decl then
         declare
            Spec : constant LAL.Subp_Spec :=
              LAL.F_Subp_Spec (LAL.As_Subp_Decl (Decl));
         begin
            if LAL.F_Subp_Returns (Spec).Is_Null then
               Put_Line ("  procedure " & Name & " loc " & Loc);
            else
               Put_Line ("  function " & Name & " loc " & Loc);
            end if;

            --  A subprogram declared without a parameter list has no
            --  Subp_Params node at all; F_Params would reject it.
            if not LAL.F_Subp_Params (Spec).Is_Null then
               for Param of LAL.F_Params (LAL.F_Subp_Params (Spec)) loop
                  for DN of LAL.F_Ids (Param) loop
                     Put_Line
                       ("    param " & Txt (DN) & " loc " & Loc_Of (DN)
                        & " mode " & Mode_Image (LAL.F_Mode (Param))
                        & " type " & Txt (LAL.F_Type_Expr (Param))
                        & " resolved "
                        & Type_Identity (LAL.F_Type_Expr (Param)));
                  end loop;
               end loop;
            end if;

            if not LAL.F_Subp_Returns (Spec).Is_Null then
               Put_Line
                 ("    returns " & Txt (LAL.F_Subp_Returns (Spec))
                  & " resolved "
                  & Type_Identity (LAL.F_Subp_Returns (Spec)));
            end if;
         end;

      elsif Decl.Kind in LCL.Ada_Subtype_Decl then
         declare
            ST : constant LAL.Subtype_Decl := LAL.As_Subtype_Decl (Decl);
            SI : constant LAL.Subtype_Indication := LAL.F_Subtype (ST);
            C  : constant LAL.Constraint := LAL.F_Constraint (SI);

            --  One static range: low .. high as a binary operation.
            procedure Put_Constraint (Range_Expr : LAL.Expr) is
               BO : constant LAL.Bin_Op := Range_Expr.As_Bin_Op;
            begin
               if not BO.Is_Null
                 and then Static_Int (BO.F_Left) /= "(dynamic)"
                 and then Static_Int (BO.F_Right) /= "(dynamic)"
               then
                  Put_Line
                    ("    constraint " & Static_Int (BO.F_Left)
                     & " .. " & Static_Int (BO.F_Right));
               else
                  Put_Line ("    constraint (dynamic)");
               end if;
            end Put_Constraint;
         begin
            Put_Line
              ("  subtype " & Name & " loc " & Loc
               & " base " & Txt (SI.F_Name)
               & " resolved " & Identity_Of (SI.F_Name));
            if C.Is_Null then
               null;

            elsif C.Kind = LCL.Ada_Range_Constraint then
               declare
                  Range_Expr : constant LAL.Expr :=
                    LAL.F_Range (LAL.F_Range (C.As_Range_Constraint));
               begin
                  Put_Constraint (Range_Expr);
               end;

            elsif C.Kind = LCL.Ada_Composite_Constraint then
               --  An index constraint: reported when it constrains
               --  exactly one index with a static range, as
               --  "String (1 .. 8)" does ([A006]); anything else —
               --  more indexes, discriminants, dynamic bounds — is
               --  reported as dynamic.
               declare
                  CC : constant LAL.Composite_Constraint :=
                    C.As_Composite_Constraint;
               begin
                  if LAL.P_Is_Index_Constraint (CC)
                    and then CC.F_Constraints.Children_Count = 1
                    and then CC.F_Constraints.First_Child.Kind
                               = LCL.Ada_Composite_Constraint_Assoc
                    and then CC.F_Constraints.First_Child
                               .As_Composite_Constraint_Assoc
                               .F_Constraint_Expr.Kind = LCL.Ada_Bin_Op
                  then
                     Put_Constraint
                       (CC.F_Constraints.First_Child
                          .As_Composite_Constraint_Assoc
                          .F_Constraint_Expr.As_Expr);
                  else
                     Put_Line ("    constraint (dynamic)");
                  end if;
               end;

            else
               Put_Line ("    constraint (dynamic)");
            end if;
         end;

      elsif Decl.Kind in LCL.Ada_Type_Decl then
         declare
            TD  : constant LAL.Type_Decl := LAL.As_Type_Decl (Decl);
            Def : constant LAL.Type_Def := LAL.F_Type_Def (TD);
         begin
            if not Def.Is_Null
              and then Def.Kind = LCL.Ada_Enum_Type_Def
            then
               Put ("  enum " & Name & " loc " & Loc
                     & " literals");
               for Lit of LAL.F_Enum_Literals (Def.As_Enum_Type_Def) loop
                  Put (" " & Txt (LAL.F_Name (Lit)));
               end loop;
               New_Line;
            else
               Put_Line
                 ("  type " & Name & " loc " & Loc
                  & " definition " & Flatten (Txt (Def)));
            end if;
         end;

      elsif Decl.Kind in LCL.Ada_Object_Decl then
         declare
            Obj      : constant LAL.Object_Decl :=
              LAL.As_Object_Decl (Decl);
            Kind : constant String :=
              (if LAL.F_Has_Constant (Obj) then "constant" else "variable");
            TE   : constant LAL.Type_Expr := LAL.F_Type_Expr (Obj);
            Type_Text : constant String :=
              (if TE.Is_Null then "<anonymous>" else Txt (TE));
            Resolved_Text : constant String :=
              (if TE.Is_Null then "unresolved" else Type_Identity (TE));
         begin
            Put_Line
              ("  " & Kind & " " & Name & " loc " & Loc
               & " type " & Type_Text
               & " resolved " & Resolved_Text
               & (if not LAL.F_Default_Expr (Obj).Is_Null
                  then " value "
                       & Static_Int (LAL.F_Default_Expr (Obj))
                  else ""));
         end;

      else
         --  No declaration may silently disappear from the dump
         --  ([S006], parser-independent model contract); kinds not
         --  covered by format 1 are reported as such.
         Put_Line
           ("  unhandled " & LAL.Kind_Name (Decl) & " loc "
            & Loc_Of (Decl));
      end if;

   exception
      when E : LCL.Property_Error =>
         Put_Line (Current_Error, "error: property error on "
                   & Name & ": "
                   & Ada.Exceptions.Exception_Message (E));
   end Put_Decl;

   Context : constant LAL.Analysis_Context := LAL.Create_Context;
   Unit    : LAL.Analysis_Unit;

   Package_Decl : LAL.Package_Decl;

begin
   if Argument_Count /= 1 then
      Put_Line (Current_Error, "usage: hac-bindgen-backend FILE.ads");
      Set_Exit_Status (2);
      return;
   end if;

   Unit := Context.Get_From_File (Input_File);

   if Unit.Has_Diagnostics then
      for Diagnostic of Unit.Diagnostics loop
         Put_Line
           (Current_Error, LAL.Format_GNU_Diagnostic (Unit, Diagnostic));
      end loop;
      Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Package_Decl :=
     LAL.As_Package_Decl
       (LAL.F_Item
          (LAL.As_Library_Item
             (LAL.F_Body
                (LAL.As_Compilation_Unit (Unit.Root)))));

   Put_Line
     ("hac-bindgen-backend " & Hac_Bindgen_Backend_Config.Crate_Version
      & " format " & Format_Version);
   Put_Line
     ("package " & Txt (Package_Decl.F_Package_Name)
      & " loc " & Loc_Of (Package_Decl.F_Package_Name));

   Put_Line ("public");
   for Decl of LAL.F_Decls (LAL.F_Public_Part (Package_Decl)) loop
      if Decl.Kind in LCL.Ada_Basic_Decl then
         Put_Decl (Decl.As_Basic_Decl);
      end if;
   end loop;

   if not LAL.F_Private_Part (Package_Decl).Is_Null then
      Put_Line ("private");
      for Decl of LAL.F_Decls (LAL.F_Private_Part (Package_Decl)) loop
         if Decl.Kind in LCL.Ada_Basic_Decl then
            Put_Decl (Decl.As_Basic_Decl);
         end if;
      end loop;
   end if;

   Put_Line ("end " & Txt (Package_Decl.F_Package_Name));
end Hac_Bindgen_Backend;
