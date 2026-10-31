-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with HAT;
with Witness_API;
with Witness_Secondary_API;

procedure Witness_HAC is

   use HAT;

   function Sum (Left, Right : Integer) return Integer is
      Result : Integer;
   begin
      Witness_API.Sum_Callback (Result, Left, Right);
      return Result;
   end Sum;

   Value         : Integer := 42;
   Direct_Real   : Real := 1.5;
   Generic_Real  : Real := 3.0;
   Message       : VString := +"HAC text";
   Flag          : Boolean := True;
   Small         : Integer := 12;
   Colour        : Witness_API.Shade := Witness_API.Green;
   P             : Witness_API.Witness_Point := (X => 1, Y => 2);
   D             : Witness_API.Witness_Point := (X => 10, Y => 20);
   R             : Witness_API.Witness_Point;

begin
   Put_Line ("HAC: calling native callback.");
   Witness_API.Say (+"Hello from HAC");
   Witness_Secondary_API.Say;
   Witness_API.Verify_Integer (Sum (20, 22));
   Witness_API.Translate_Callback (R, P, D);
   if R.X = 11 and then R.Y = 22 then
      Put_Line ("HAC: record exchange OK.");
   else
      Put_Line ("HAC: record exchange MISMATCH.");
   end if;
   Witness_API.Check_Values
     (Value, Direct_Real, Generic_Real, Message, Flag, Small, Colour);
   Witness_API.Verify_Results
     (Direct_Real, Generic_Real, Flag, Small, Colour);
   Witness_API.Echo_String (Message);
   Witness_API.Verify_String (Message);
   Put_Line ("HAC: procedure imports, conversions, and copy-back passed.");
end Witness_HAC;
