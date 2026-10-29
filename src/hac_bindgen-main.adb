--------------------------------------------------------------------------------
--  hac_bindgen - binding generator for embedded HAC
--  Copyright 2026 Lionel Draghi
--  Apache-2.0 (see LICENSE)
--
--  Main program: dispatch the command line to the CLI.
--------------------------------------------------------------------------------

with Hac_Bindgen.CLI;

procedure Hac_Bindgen.Main is
begin
   Hac_Bindgen.CLI.Run;
end Hac_Bindgen.Main;
