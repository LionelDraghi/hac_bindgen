--------------------------------------------------------------------------------
--  hac_bindgen - binding generator for embedded HAC
--  Copyright 2026 Lionel Draghi
--  Apache-2.0 (see LICENSE)
--
--  Root package: project identity and version. The version reported by
--  the CLI (hac-bindgen --version) and the version stamped in every
--  generated file header both come from here (spec [S002]).
--------------------------------------------------------------------------------

package Hac_Bindgen is

   Tool_Name : constant String := "hac-bindgen";
   Version   : constant String := "0.1.0-dev";

end Hac_Bindgen;
