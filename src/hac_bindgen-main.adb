-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Main program: dispatch the command line to the CLI.
-- -----------------------------------------------------------------------------

with Hac_Bindgen.CLI;

procedure Hac_Bindgen.Main is
begin
   Hac_Bindgen.CLI.Run;
end Hac_Bindgen.Main;
