--------------------------------------------------------------------------------
--  hac_bindgen witness - native callbacks registered into the HAC VM
--  Copyright 2026 Lionel Draghi
--  Apache-2.0 (see LICENSE)
--------------------------------------------------------------------------------
with Ada.Text_IO;

with HAC_Sys.Interfacing;

package body Witness_Native is

   use Ada.Text_IO;
   use HAC_Sys.Interfacing;

   procedure Say (Data : in out HAC_Element_Array) is
   begin
      Put_Line ("Native: HAC says: [" & To_Native (Data (1)) & ']');
   end Say;

