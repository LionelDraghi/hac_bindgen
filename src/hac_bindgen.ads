--  -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Root package: project identity and version. The version reported by
--  the CLI (hac-bindgen --version) and the version stamped in every
--  generated file header both come from here — a rename of the
--  Crate_Version that Alire generates from alire.toml: one single
--  source of truth for the version.
-- -----------------------------------------------------------------------------

with Hac_Bindgen_Config;

package Hac_Bindgen is

   Tool_Name : constant String := "hac-bindgen";
   Version   : String renames Hac_Bindgen_Config.Crate_Version;

end Hac_Bindgen;
