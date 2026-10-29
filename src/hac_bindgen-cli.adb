-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;

package body Hac_Bindgen.CLI is

   package CL  renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package TIO renames Ada.Text_IO;

   use type Dir.File_Kind;

   Run_Error : exception;

   procedure Fail (Message : String);

   procedure Put_Usage (Stream : TIO.File_Type);

   function File_Exists (Name : String) return Boolean;

   ---------------------------------------------------------------------

   procedure Fail (Message : String) is
   begin
      TIO.Put_Line (TIO.Standard_Error, "error: " & Message);
      Put_Usage (TIO.Standard_Error);
      CL.Set_Exit_Status (CL.Failure);
      raise Run_Error;
   end Fail;

   ---------------------------------------------------------------------

   procedure Put_Usage (Stream : TIO.File_Type) is
   begin
      TIO.Put_Line (Stream, "usage: hac-bindgen generate SOURCE... [--output-dir DIR]");
      TIO.Put_Line (Stream, "       hac-bindgen check SOURCE... [--output-dir DIR]");
      TIO.Put_Line (Stream, "       hac-bindgen --version");
      TIO.Put_Line (Stream, "       hac-bindgen --help");
   end Put_Usage;

   ---------------------------------------------------------------------

   function File_Exists (Name : String) return Boolean is
   begin
      return Dir.Exists (Name)
             and then Dir.Kind (Name) = Dir.Ordinary_File;
   exception
      when Dir.Name_Error =>
         return False;
   end File_Exists;

   ---------------------------------------------------------------------

   procedure Run is
   begin
      if CL.Argument_Count = 0 then
         --  No argument: same behavior as --help ([A001]).
         Put_Usage (TIO.Standard_Output);
         CL.Set_Exit_Status (CL.Success);
         return;
      end if;

      declare
         Command : constant String := CL.Argument (1);
      begin
         if Command = "--version" then
            TIO.Put_Line (Hac_Bindgen.Tool_Name & " " & Hac_Bindgen.Version);
            return;

         elsif Command = "--help" then
            Put_Usage (TIO.Standard_Output);
            CL.Set_Exit_Status (CL.Success);
            return;

         elsif Command = "generate"
           or else Command = "check"
         then
            if CL.Argument_Count < 2 then
               Fail ("missing source file");
            end if;

            declare
               First_Source : Natural := 0;
            begin
               for I in 2 .. CL.Argument_Count loop
                  declare
                     Source : constant String := CL.Argument (I);
                  begin
                     exit when Source (Source'First) = '-';  --  next option
                     if not File_Exists (Source) then
                        Fail ("cannot read '" & Source & "'");
                     end if;
                     if First_Source = 0 then
                        First_Source := I;
                     end if;
                  end;
               end loop;

               --  M3/M4: analysis, traversal and generation.
               TIO.Put_Line
                 (TIO.Standard_Error,
                  Hac_Bindgen.Tool_Name & ": " & Command & " "
                  & CL.Argument (First_Source)
                  & " is not implemented yet (see docs/roadmap.md, M3 and M4)");
               CL.Set_Exit_Status (CL.Failure);
            end;

         else
            Fail ("invalid command '" & Command & "'");
         end if;
      end;
   exception
      when Run_Error =>
         null;  --  message and status already emitted by Fail
   end Run;

end Hac_Bindgen.CLI;
