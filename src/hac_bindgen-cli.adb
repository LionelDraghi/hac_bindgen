-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Text_IO;
with Hac_Bindgen.Analysis;

package body Hac_Bindgen.CLI is

   package CL  renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package TIO renames Ada.Text_IO;

   use type Dir.File_Kind;

   Run_Error : exception;

   procedure Fail (Message : String; With_Usage : Boolean := True);

   procedure Put_Usage (Stream : TIO.File_Type);

   function File_Exists (Name : String) return Boolean;

   ---------------------------------------------------------------------

   procedure Fail (Message : String; With_Usage : Boolean := True) is
   begin
      TIO.Put_Line (TIO.Standard_Error, "error: " & Message);
      if With_Usage then
         Put_Usage (TIO.Standard_Error);
      end if;
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

            for I in 2 .. CL.Argument_Count loop
               declare
                  Source : constant String := CL.Argument (I);
               begin
                  exit when Source (Source'First) = '-';  --  next option
                  if not File_Exists (Source) then
                     Fail ("cannot read '" & Source & "'");
                  end if;

                  if Command = "check" then
                     --  M3: the analysis front-end builds and validates
                     --  the model; the traversal classification itself
                     --  is the next step ([S006], B001).
                     begin
                        Analysis.Check (Source);
                     exception
                        when Error : Analysis.Analysis_Error =>
                           Fail (Ada.Exceptions.Exception_Message (Error),
                                 With_Usage => False);
                     end;
                  end if;
               end;
            end loop;

            if Command = "check" then
               --  Every source analyzed and validated; the traversal
               --  and the generation are M3/M4 work.
               CL.Set_Exit_Status (CL.Success);
            else
               --  M4: generation.
               TIO.Put_Line
                 (TIO.Standard_Error,
                  Hac_Bindgen.Tool_Name & ": generate is not implemented yet"
                  & " (see docs/roadmap.md, M4)");
               CL.Set_Exit_Status (CL.Failure);
            end if;

         else
            Fail ("invalid command '" & Command & "'");
         end if;
      end;
   exception
      when Run_Error =>
         null;  --  message and status already emitted by Fail
   end Run;

end Hac_Bindgen.CLI;
