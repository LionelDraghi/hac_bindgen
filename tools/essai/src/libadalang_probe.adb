with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Libadalang.Analysis;

procedure Libadalang_Probe is
   package LAL renames Libadalang.Analysis;

   Context : constant LAL.Analysis_Context := LAL.Create_Context;
   Unit    : constant LAL.Analysis_Unit :=
     Context.Get_From_File ("fixture.ads");
   Package_Decl : constant LAL.Package_Decl :=
     LAL.As_Package_Decl
       (LAL.F_Item
          (LAL.As_Library_Item
             (LAL.F_Body
                (LAL.As_Compilation_Unit (Unit.Root)))));
begin
   if Unit.Has_Diagnostics then
      for Diagnostic of Unit.Diagnostics loop
         Put_Line (LAL.Format_GNU_Diagnostic (Unit, Diagnostic));
      end loop;
      Set_Exit_Status (Failure);
      return;
   end if;

   Put_Line ("Public declarations:");
   for Decl of LAL.F_Decls (LAL.F_Public_Part (Package_Decl)) loop
      Put_Line
        ("  " & LAL.Kind_Name (Decl) & ": " & LAL.Image (Decl));

      if Decl.Kind in LAL.Subp_Decl then
         declare
            Spec : constant LAL.Subp_Spec :=
              LAL.F_Subp_Spec (LAL.As_Subp_Decl (Decl));
         begin
            for Param of LAL.F_Params (LAL.F_Subp_Params (Spec)) loop
               Put_Line
                 ("    parameter " & LAL.Image (Param)
                  & " mode=" & LAL.Image (LAL.F_Mode (Param))
                  & " type="
                  & LAL.Image (LAL.F_Type_Expr (Param)));
            end loop;

            if not LAL.F_Subp_Returns (Spec).Is_Null then
               Put_Line
                 ("    result type="
                  & LAL.Image (LAL.F_Subp_Returns (Spec)));
            end if;
         end;
      end if;
   end loop;
end Libadalang_Probe;
