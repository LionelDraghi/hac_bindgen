-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Analysis front-end: run the analysis backend executable on a
--  package specification and build the binding model from its dump.
--  The backend lives in its own crate (tools/libadalang_backend) and
--  is never linked here; see the backend isolation decision in
--  docs/dev/design_discussions.md.
-- -----------------------------------------------------------------------------

with Hac_Bindgen.Model;

package Hac_Bindgen.Analysis is

   Analysis_Error : exception;

   function Analyze (Source_Path : String) return Model.Package_Model;
   --  Run the analysis backend on Source_Path and return the model
   --  built from its dump. Raises Analysis_Error when the backend
   --  cannot be run, rejects the input, or returns an invalid dump;
   --  the message starts with the source path.

   procedure Check (Source_Path : String);
   --  Analyze Source_Path and validate the resulting model without
   --  keeping it; raises Analysis_Error like Analyze.

end Hac_Bindgen.Analysis;
