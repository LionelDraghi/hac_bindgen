-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Environment_Variables;
with Ada.Exceptions;
with GNAT.Expect;
with GNAT.OS_Lib;
with Hac_Bindgen.Dump_Reader;

package body Hac_Bindgen.Analysis is

   Backend_Relative_Paths : constant array (1 .. 2) of
     access constant String :=
       [new String'("../tools/libadalang_backend/bin/hac_bindgen_backend"),
        new String'("tools/libadalang_backend/bin/hac_bindgen_backend")];
   --  The first path is valid when the tool is run from tests/, as the
   --  bbt scenarios do; the second from the repository root.

   Backend_Variable : constant String := "HAC_BINDGEN_BACKEND";

   function Locate_Backend return String is
   begin
      if Ada.Environment_Variables.Exists (Backend_Variable) then
         declare
            Path : constant String :=
              Ada.Environment_Variables.Value (Backend_Variable);
         begin
            if GNAT.OS_Lib.Is_Regular_File (Path) then
               return Path;
            end if;
         end;
      end if;

      for Path of Backend_Relative_Paths loop
         if GNAT.OS_Lib.Is_Regular_File (Path.all) then
            return Path.all;
         end if;
      end loop;

      return "";
   end Locate_Backend;

   --  Strip the trailing newline of the backend diagnostics, for a
   --  message layout that stays on the error line.
   function Trim_Newline (S : String) return String is
      Last : Natural := S'Last;
   begin
      while Last >= S'First
        and then (S (Last) = ASCII.LF or else S (Last) = ASCII.CR)
      loop
         Last := Last - 1;
      end loop;
      return S (S'First .. Last);
   end Trim_Newline;

   function Analyze (Source_Path : String) return Model.Package_Model is
      Backend : constant String := Locate_Backend;
   begin
      if Backend = "" then
         raise Analysis_Error with
           Source_Path
           & ": analysis backend not found (set " & Backend_Variable
           & " or build tools/libadalang_backend)";
      end if;

      declare
         use GNAT.Expect;

         Status : aliased Integer;
         --  On success the dump is the only output (the backend writes
         --  diagnostics on standard error only when it fails), so the
         --  merged capture is exactly the dump.
         Output : constant String := Get_Command_Output
           (Backend,
            [1 => new String'(Source_Path)],
            "",
            Status'Access,
            Err_To_Out => True);
      begin
         if Status /= 0 then
            raise Analysis_Error with
              Source_Path & ": the analysis backend rejected the input:"
              & (if Output = "" then "" else ASCII.LF & Trim_Newline (Output));
         end if;

         return Hac_Bindgen.Dump_Reader.Read (Output);
      exception
         when Error : Hac_Bindgen.Dump_Reader.Dump_Error
                    | Hac_Bindgen.Model.Model_Error =>
            raise Analysis_Error with
              Source_Path & ": invalid analysis dump: "
              & Ada.Exceptions.Exception_Message (Error);
      end;
   end Analyze;

   ---------------------------------------------------------------------

   procedure Check (Source_Path : String) is
      Result : Model.Package_Model := Analyze (Source_Path);
      pragma Unreferenced (Result);
   begin
      null;
   end Check;

end Hac_Bindgen.Analysis;
