-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Facade generation for the scalar profile ([A002]): emit the HAC-side
--  package, the native adapter, and the registration, from the binding
--  model and its classification. The emitted shapes reproduce the
--  patterns verified by the M2 evidence
--  (docs/dev/hac_interfacing_notes.md) and the manual witness.
-- -----------------------------------------------------------------------------

with Hac_Bindgen.Model;

package Hac_Bindgen.Generation is

   Generation_Error : exception;

   procedure Generate
     (Pkg         : Model.Package_Model;
      Result      : Model.Analysis_Result;
      Hac_Package : String;
      Output_Dir  : String);
   --  Emit the generated files of one package into Output_Dir ("" means
   --  the current directory). Hac_Package is the HAC-side package name:
   --  the API name, or the --hac-package value. Only the declarations
   --  classified Bindable take part; the caller ran the traversal
   --  first and reported its warnings. Raises Generation_Error when a
   --  file cannot be written.

end Hac_Bindgen.Generation;
