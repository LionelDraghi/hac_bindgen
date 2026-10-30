-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Hac_Bindgen.Model;

package Hac_Bindgen.Dump_Reader is

   Dump_Error : exception;
   --  Raised when the dump does not conform to the format-1 grammar:
   --  wrong format number, malformed line, unexpected section or
   --  trailing content.

   function Read (Dump : String) return Model.Package_Model;
   --  Parse one format-1 dump and return the package model it
   --  describes. Only the public section enters the model; the private
   --  section is checked for conformance and dropped, since only
   --  public declarations are candidates ([S006]).

end Hac_Bindgen.Dump_Reader;
