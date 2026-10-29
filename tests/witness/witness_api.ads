-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with HAT;

package Witness_API is

   type Shade is (Red, Green, Blue);

   procedure Say (Message : in HAT.VString) with Import => True;

   procedure Sum_Callback
     (Result : out Integer;
      Left   : in Integer;
      Right  : in Integer)
   with Import => True;

   procedure Verify_Integer (Value : in Integer) with Import => True;

   procedure Check_Values
     (Value         : in Integer;
      Direct_Real   : in out HAT.Real;
      Generic_Real  : in out HAT.Real;
      Message       : in HAT.VString;
      Flag          : in out Boolean;
      Small         : in out Integer;
      Colour        : in out Shade)
   with Import => True;

   procedure Verify_Results
     (Direct_Real  : in HAT.Real;
      Generic_Real : in HAT.Real;
      Flag         : in Boolean;
      Small        : in Integer;
      Colour       : in Shade)
   with Import => True;

   procedure Echo_String (Value : in out HAT.VString) with Import => True;
   procedure Verify_String (Value : in HAT.VString) with Import => True;

   procedure Trigger_Type_Error (Value : in Integer) with Import => True;
   procedure Trigger_Range_Error (Value : in Integer) with Import => True;
   procedure Trigger_Native_Error with Import => True;

end Witness_API;
