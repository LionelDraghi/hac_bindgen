-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  End-to-end test harness (A002): a static witness application that
--  embeds HAC, registers the bindings of the scenario's generated
--  adapter through the Witness_Binding renames, then builds and runs
--  the script given as command-line argument. This file never changes
--  when the tested API grows ([S009]): only the per-scenario
--  witness_binding.ads names the generated adapter.
--
--  The witness moves to the script's directory before the build, so
--  HAC resolves the script's withed units there, next to the
--  generated HAC-side files.
--
--  Exit status: 0 when every script ran without VM error, 1 otherwise.
-- -----------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with HAC_Sys.Builder;
with HAC_Sys.PCode.Interpreter;
with Witness_Binding;

procedure Witness_Main is
   use Ada.Text_IO;
   use HAC_Sys.PCode.Interpreter;

   BD : HAC_Sys.Builder.Build_Data;

   --  Adapt HAC's generic traceback callback to a readable line.
   procedure Print_Trace_Line
     (File_Name   : String;
      Block_Name  : String;
      Line_Number : Positive)
   is
   begin
      Put_Line
        ("HAC traceback: " & File_Name & ":"
         & Positive'Image (Line_Number) & " in " & Block_Name);
   end Print_Trace_Line;

   procedure Print_Trace is new Show_Trace_Back (Print_Trace_Line);

begin
   if Ada.Command_Line.Argument_Count = 0 then
      Put_Line (Current_Error, "usage: witness_main SCRIPT...");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Witness_Binding.Register_All (BD);

   --  Resolve every script to an absolute path before the first
   --  Set_Directory: a relative argument would otherwise be resolved
   --  against the previous script's directory ([A008]).
   declare
      use Ada.Strings.Unbounded;

      Count : constant Positive := Ada.Command_Line.Argument_Count;

      type Script_List is array (1 .. Count) of Unbounded_String;

      Scripts : Script_List;
   begin
      for A in Scripts'Range loop
         Scripts (A) := To_Unbounded_String
           (Ada.Directories.Full_Name (Ada.Command_Line.Argument (A)));
      end loop;

      for A in Scripts'Range loop
         declare
            Script      : constant String := To_String (Scripts (A));
            Post_Mortem : Post_Mortem_Data;
         begin
            Ada.Directories.Set_Directory
              (Ada.Directories.Containing_Directory (Script));

            BD.Build_Main_from_File (Ada.Directories.Simple_Name (Script));
            if not BD.Build_Successful then
               Put_Line (Current_Error, "HAC failed to build " & Script);
               Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
               return;
            end if;

            Interpret_on_Current_IO (BD, 0, Script, Post_Mortem);
            if Is_Exception_Raised (Post_Mortem.Unhandled) then
               Put_Line
                 (Current_Error,
                  "HAC VM exception: " & Message (Post_Mortem.Unhandled));
               Print_Trace (Post_Mortem.Unhandled);
               Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
               return;
            else
               Put_Line ("E2E: script completed.");
            end if;
         end;
      end loop;
   end;
end Witness_Main;
