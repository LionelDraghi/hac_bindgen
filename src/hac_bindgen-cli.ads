--------------------------------------------------------------------------------
--  hac_bindgen - binding generator for embedded HAC
--  Copyright 2026 Lionel Draghi
--  Apache-2.0 (see LICENSE)
--
--  Command-line interface (spec [S010], features A001 and C001).
--
--  The command surface:
--
--     hac-bindgen generate SOURCE... [--output-dir DIR]
--     hac-bindgen check    SOURCE... [--output-dir DIR]
--     hac-bindgen --version
--     hac-bindgen --help
--
--  M1 scope: version, help, usage errors, and input-file checks for
--  check and generate. The traversal and the generation themselves are
--  M3/M4 work; the two commands report their not-yet-implemented
--  status until then.
--------------------------------------------------------------------------------

package Hac_Bindgen.CLI is

   --  Run the command line; never returns: the process exits with the
   --  command status (0 on success, 1 on any error, spec [S010]).
   procedure Run;

end Hac_Bindgen.CLI;
