-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with HAC_Sys.Builder;
with HAC_Sys.PCode.Interpreter;
with Witness_Native;

procedure Witness_Main is
   use Ada.Text_IO;
   use HAC_Sys.PCode.Interpreter;

   BD : HAC_Sys.Builder.Build_Data;

   --  Adapt HAC's generic traceback callback to a readable witness line.
   procedure Print_Trace_Line
     (File_Name   : String;
      Block_Name  : String;
      Line_Number : Positive)
   is
   begin
      Put_Line
        ("HAC traceback: " & File_Name & ":" & Positive'Image (Line_Number)
         & " in " & Block_Name);
   end Print_Trace_Line;

   procedure Print_Trace is new Show_Trace_Back (Print_Trace_Line);

   --  An empty expected message means the script must finish without a VM error.
   procedure Build_And_Run
     (Source           : String;
      Expected_Message : String := "")
   is
      Post_Mortem : Post_Mortem_Data;
   begin
      BD.Build_Main_from_File (Source);
      if not BD.Build_Successful then
         Put_Line (Current_Error, "HAC failed to build " & Source);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         return;
      end if;

      Interpret_on_Current_IO (BD, 0, Source, Post_Mortem);
      if Expected_Message'Length = 0 then
         if Is_Exception_Raised (Post_Mortem.Unhandled) then
            Put_Line
              (Current_Error,
               "Unexpected HAC VM exception: " & Message (Post_Mortem.Unhandled));
            Print_Trace (Post_Mortem.Unhandled);
            Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         end if;
      elsif not Is_Exception_Raised (Post_Mortem.Unhandled) then
         Put_Line (Current_Error, "Expected HAC VM exception was not raised by " & Source);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      elsif Ada.Strings.Fixed.Index (Message (Post_Mortem.Unhandled), Expected_Message) = 0 then
         Put_Line
           (Current_Error,
            "Unexpected HAC VM exception: " & Message (Post_Mortem.Unhandled));
         Print_Trace (Post_Mortem.Unhandled);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      else
         Put_Line
           ("Verified callback error from " & Source & ": "
            & Image (Post_Mortem.Unhandled) & ": "
            & Message (Post_Mortem.Unhandled));
         Print_Trace (Post_Mortem.Unhandled);
      end if;
   end Build_And_Run;
begin
   --  Keep one Build_Data so the registered callbacks are reused across scripts.
   Witness_Native.Register_All (BD);
   Build_And_Run ("witness_hac.adb");
   Build_And_Run
     ("witness_type_error.adb",
      "Exception raised in callback, message: Expected a HAT.Real");
   Build_And_Run
     ("witness_range_error.adb",
      "range check failed");
   Build_And_Run
     ("witness_native_error.adb",
      "Exception raised in callback, message: witness native failure");
end Witness_Main;
