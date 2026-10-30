-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Traversal: classify every public declaration of a package model as
--  bindable or not ([S006]), and report the classification. Warnings
--  are normal output: they go to standard output, next to the summary;
--  the standard error is reserved for the cases where the tool itself
--  is in difficulty.
-- -----------------------------------------------------------------------------

with Hac_Bindgen.Model;

package Hac_Bindgen.Traversal is

   function Classify
     (Pkg : Model.Package_Model) return Model.Analysis_Result;
   --  Classify every declaration of the model. The result covers every
   --  declaration, and is validated against the model before being
   --  returned (a classification gap is a bug, not a warning).

   procedure Report
     (Pkg  : Model.Package_Model;
      Result : Model.Analysis_Result);
   --  Write one warning line per non-bindable item, then the summary
   --  line, to standard output.

end Hac_Bindgen.Traversal;
