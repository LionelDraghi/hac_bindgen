-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with HAC_Sys.Builder;

package Witness_Native is

   --  Native callbacks registered into the embedded HAC environment.
   --  Manual witness of the callback surface that hac-bindgen will
   --  generate (M2 evidence, see docs/dev/hac_interfacing_notes.md).

   procedure Register_All (BD : HAC_Sys.Builder.Build_Data);

end Witness_Native;
