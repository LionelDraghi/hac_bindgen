with Ada.Command_Line; use Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO; use Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Langkit_Support.Slocs;
with Langkit_Support.Text;
with Libadalang.Analysis;
with Libadalang.Common;
with Libadalang.Expr_Eval;

procedure Libadalang_Probe is
   package LAL renames Libadalang.Analysis;
   package LCL renames Libadalang.Common;
   package LEE renames Libadalang.Expr_Eval;
   package LST renames Langkit_Support.Text;

   Context : constant LAL.Analysis_Context := LAL.Create_Context;
   Unit    : constant LAL.Analysis_Unit :=
     Context.Get_From_File ("probe_fixture.ads");

   Package_Decl : constant LAL.Package_Decl :=
     LAL.As_Package_Decl
       (LAL.F_Item
          (LAL.As_Library_Item
             (LAL.F_Body
                (LAL.As_Compilation_Unit (Unit.Root)))));

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

   --  Source text of a node, as UTF-8.
   function Txt (Node : LAL.Ada_Node'Class) return String is
   begin
      if Node.Is_Null then
         return "";
      end if;
      return LST.Encode (LAL.Text (Node), "utf-8");
   end Txt;

   function Sloc_Of (Node : LAL.Ada_Node'Class) return String is
      SR : constant Langkit_Support.Slocs.Source_Location_Range :=
        LAL.Sloc_Range (Node);
   begin
      return Trim (SR.Start_Line'Image) & ":" & Trim (SR.Start_Column'Image);
   end Sloc_Of;

   function Name_Of (Decl : LAL.Basic_Decl'Class) return String is
      DN : constant LAL.Defining_Name := Decl.P_Defining_Name;
   begin
      if DN.Is_Null then
         return "(no name)";
      end if;
      return Txt (DN);
   end Name_Of;

   --  Resolve a Name node to its declaration, and describe the result:
   --  node kind, name, defining unit and source position.
   function Resolve_Name (N : LAL.Name'Class) return String is
      Decl : constant LAL.Basic_Decl := N.P_Referenced_Decl;
   begin
      if Decl.Is_Null then
         return "(unresolved)";
      end if;
      return LAL.Kind_Name (Decl) & " '" & Name_Of (Decl) & "' ["
        & LAL.Get_Filename (Decl.Unit) & " " & Sloc_Of (Decl) & "]";
   exception
      when LCL.Property_Error =>
         return "(resolution failed)";
   end Resolve_Name;

   --  Describe a type expression: source text plus resolved declaration.
   function Type_Expr_Info (TE : LAL.Type_Expr'Class) return String is
      SI : constant LAL.Subtype_Indication := TE.As_Subtype_Indication;
   begin
      if SI.Is_Null then
         return "source=" & Txt (TE) & " resolved=(not a subtype indication)";
      end if;
      return "source=" & Txt (TE) & " resolved=" & Resolve_Name (SI.F_Name);
   end Type_Expr_Info;

   function Mode_Image (M : LAL.Mode) return String is
   begin
      case M.Kind is
         when LCL.Ada_Mode_In      => return "in";
         when LCL.Ada_Mode_In_Out  => return "in out";
         when LCL.Ada_Mode_Out     => return "out";
         when LCL.Ada_Mode_Default => return "(default = in)";
         when others               => return "?";
      end case;
   end Mode_Image;

   --  Static value of an expression, if it is a static expression.
   function Static_Value (E : LAL.Expr'Class) return String is
      R : constant LEE.Eval_Result := LEE.Expr_Eval (E.As_Expr);
   begin
      case R.Kind is
         when LEE.Int =>
            return "static value="
              & GNATCOLL.GMP.Integers.Image (R.Int_Result);
         when others =>
            return "static value=" & LEE.Image (R);
      end case;
   exception
      when LCL.Property_Error =>
         return "(not statically evaluable)";
   end Static_Value;

   procedure Dump_Decl (Decl : LAL.Basic_Decl'Class; Part : String) is
   begin
      Put_Line
        ("  [" & Part & "] kind=" & LAL.Kind_Name (Decl)
         & " name='" & Name_Of (Decl) & "' sloc=" & Sloc_Of (Decl));

      --  Subprograms --------------------------------------------------------
      if Decl.Kind in LCL.Ada_Subp_Decl | LCL.Ada_Null_Subp_Decl then
         declare
            Spec : constant LAL.Subp_Spec :=
              LAL.F_Subp_Spec (LAL.As_Subp_Decl (Decl));
            Subp_Name : constant LAL.Defining_Name := LAL.F_Subp_Name (Spec);
            Is_Function : constant Boolean := not LAL.F_Subp_Returns (Spec).Is_Null;
         begin
            Put_Line
              ("    subprogram " & (if Is_Function then "function" else "procedure")
               & " name='" & Txt (Subp_Name) & "'");

            for Param of LAL.F_Params (LAL.F_Subp_Params (Spec)) loop
               for DN of LAL.F_Ids (Param) loop
                  Put_Line
                    ("    parameter name='" & Txt (DN)
                     & "' mode=" & Mode_Image (LAL.F_Mode (Param))
                     & " type " & Type_Expr_Info (LAL.F_Type_Expr (Param)));
                  if not LAL.F_Default_Expr (Param).Is_Null then
                     Put_Line
                       ("      default=" & Txt (LAL.F_Default_Expr (Param))
                        & " " & Static_Value (LAL.F_Default_Expr (Param)));
                  end if;
               end loop;
            end loop;

            if Is_Function then
               Put_Line
                 ("    result type " & Type_Expr_Info (LAL.F_Subp_Returns (Spec)));
            end if;
         end;

      --  Type declarations ---------------------------------------------------
      elsif Decl.Kind in LCL.Ada_Type_Decl then
         declare
            TD   : constant LAL.Type_Decl := LAL.As_Type_Decl (Decl);
            Def  : constant LAL.Enum_Type_Def :=
              LAL.F_Type_Def (TD).As_Enum_Type_Def;
         begin
            if not Def.Is_Null then
               Put ("    enumeration literals:");
               for Lit of LAL.F_Enum_Literals (Def) loop
                  Put
                    (" '" & Txt (LAL.F_Name (Lit)) & "'"
                     & "(" & Sloc_Of (Lit) & ")");
               end loop;
               New_Line;
            else
               Put_Line
                 ("    type definition (source): "
                  & Txt (LAL.F_Type_Def (TD)));
            end if;
         end;

      --  Subtype declarations -------------------------------------------------
      elsif Decl.Kind in LCL.Ada_Subtype_Decl then
         declare
            ST : constant LAL.Subtype_Decl := LAL.As_Subtype_Decl (Decl);
            SI : constant LAL.Subtype_Indication := LAL.F_Subtype (ST);
            C  : constant LAL.Constraint := LAL.F_Constraint (SI);
            RC : constant LAL.Range_Constraint := C.As_Range_Constraint;
         begin
            Put_Line
              ("    base type (source): " & Txt (SI.F_Name)
               & " resolved=" & Resolve_Name (SI.F_Name));
            if not RC.Is_Null then
               declare
                  Range_Expr : constant LAL.Expr :=
                    LAL.F_Range (LAL.F_Range (RC));
               begin
                  Put_Line ("    constraint: range " & Txt (Range_Expr));
                  declare
                     BO : constant LAL.Bin_Op := Range_Expr.As_Bin_Op;
                  begin
                     if not BO.Is_Null then
                        Put_Line
                          ("      lower bound: " & Static_Value (BO.F_Left)
                           & "  upper bound: " & Static_Value (BO.F_Right));
                     end if;
                  end;
               end;
            else
               Put_Line ("    constraint: none");
            end if;
            declare
               Base_Sub : constant LAL.Base_Type_Decl := ST.P_Base_Subtype;
               Base_Types : constant LAL.Base_Type_Decl_Array :=
                 ST.P_Base_Types (Origin => ST.As_Ada_Node);
            begin
               if Base_Sub.Is_Null then
                  Put_Line ("    P_Base_Subtype: (null)");
               else
                  Put_Line
                    ("    P_Base_Subtype: " & LAL.Kind_Name (Base_Sub)
                     & " '" & Name_Of (Base_Sub) & "' ["
                     & LAL.Get_Filename (Base_Sub.Unit) & "]");
               end if;
               for BT of Base_Types loop
                  Put_Line
                    ("    P_Base_Types entry: " & LAL.Kind_Name (BT)
                     & " '" & Name_Of (BT) & "' ["
                     & LAL.Get_Filename (BT.Unit) & "]");
               end loop;
            end;
         end;

      --  Objects and constants -------------------------------------------------
      elsif Decl.Kind in LCL.Ada_Object_Decl then
         declare
            Obj      : constant LAL.Object_Decl := LAL.As_Object_Decl (Decl);
            Constant_Flag : constant String :=
              (if LAL.F_Has_Constant (Obj) then "constant" else "variable");
         begin
            Put_Line ("    object kind: " & Constant_Flag);
            Put_Line ("    type " & Type_Expr_Info (LAL.F_Type_Expr (Obj)));
            if not LAL.F_Default_Expr (Obj).Is_Null then
               declare
                  DE : constant LAL.Expr := LAL.F_Default_Expr (Obj);
               begin
                  Put_Line ("    default expression: " & Txt (DE));
                  Put_Line ("    " & Static_Value (DE));
               end;
            else
               Put_Line ("    default expression: none");
            end if;
         end;
      end if;

   exception
      when E : LCL.Property_Error =>
         Put_Line
           ("    !! property error while dumping: "
            & Ada.Exceptions.Exception_Message (E));
   end Dump_Decl;

begin
   if Unit.Has_Diagnostics then
      for Diagnostic of Unit.Diagnostics loop
         Put_Line (LAL.Format_GNU_Diagnostic (Unit, Diagnostic));
      end loop;
      Set_Exit_Status (Failure);
      return;
   end if;

   Put_Line ("=== Libadalang probe: probe_fixture.ads ===");
   Put_Line ("");

   Put_Line ("--- Public part ---");
   for Decl of LAL.F_Decls (LAL.F_Public_Part (Package_Decl)) loop
      Dump_Decl (Decl.As_Basic_Decl, "public");
   end loop;

   Put_Line ("");
   Put_Line ("--- Private part ---");
   for Decl of LAL.F_Decls (LAL.F_Private_Part (Package_Decl)) loop
      Dump_Decl (Decl.As_Basic_Decl, "private");
   end loop;
end Libadalang_Probe;
