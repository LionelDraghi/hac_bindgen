-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Text_IO;

with HAC_Sys.Interfacing;

package body Witness_Native is

   use Ada.Text_IO;
   use HAC_Sys.Interfacing;

   type Small_Integer is range -100 .. 100;
   type Shade is (Red, Green, Blue);
   type Generic_Real is digits 6;

   function To_Native_Boolean is new To_Native_Any_Enum (Boolean);
   function To_HAC_Boolean is new To_HAC_Any_Enum (Boolean);
   function To_Native_Small is new To_Native_Any_Integer (Small_Integer);
   function To_HAC_Small is new To_HAC_Any_Integer (Small_Integer);
   function To_Native_Shade is new To_Native_Any_Enum (Shade);
   function To_HAC_Shade is new To_HAC_Any_Enum (Shade);
   function To_Native_Real is new To_Native_Any_Float (Generic_Real);
   function To_HAC_Real is new To_HAC_Any_Float (Generic_Real);

   procedure Say (Data : in out HAC_Element_Array) is
   begin
      Put_Line ("Native: HAC says: [" & To_Native (Data (1)) & ']');
   end Say;

   procedure Secondary_Say (Data : in out HAC_Element_Array) is
      pragma Unreferenced (Data);
   begin
      Put_Line ("Native: secondary package callback.");
   end Secondary_Say;

   procedure Sum_Callback (Data : in out HAC_Element_Array) is
      Left  : constant Integer := To_Native (Data (2));
      Right : constant Integer := To_Native (Data (3));
   begin
      Data (1) := To_HAC (Left + Right);
   end Sum_Callback;

   procedure Verify_Integer (Data : in out HAC_Element_Array) is
   begin
      if To_Native (Data (1)) /= 42 then
         raise Program_Error with "witness assertion failed: function result slot";
      end if;
   end Verify_Integer;

   procedure Check_Values (Data : in out HAC_Element_Array) is
      Direct_Real  : constant Long_Float := To_Native (Data (2));
      Generic_Value : constant Generic_Real := To_Native_Real (Data (3));
   begin
      if To_Native (Data (1)) /= 42
        or else Direct_Real /= 1.5
        or else Generic_Value /= 3.0
        or else To_Native (Data (4)) /= "HAC text"
        or else not To_Native_Boolean (Data (5))
        or else To_Native_Small (Data (6)) /= 12
      then
         raise Program_Error with "witness assertion failed: callback inputs";
      end if;

      case To_Native_Shade (Data (7)) is
         when Red =>
            raise Program_Error with "witness assertion failed: enum input was Red";
         when Green =>
            null;
         when Blue =>
            raise Program_Error with "witness assertion failed: enum input was Blue";
      end case;

      Data (2) := To_HAC (Direct_Real + 0.5);
      Data (3) := To_HAC_Real (Generic_Value + 0.5);
      Data (5) := To_HAC_Boolean (False);
      Data (6) := To_HAC_Small (To_Native_Small (Data (6)) + 1);
      Data (7) := To_HAC_Shade (Shade'Succ (To_Native_Shade (Data (7))));
   end Check_Values;

   procedure Verify_Results (Data : in out HAC_Element_Array) is
      Direct_Real   : constant Long_Float := To_Native (Data (1));
      Generic_Value : constant Generic_Real := To_Native_Real (Data (2));
   begin
      if Direct_Real /= 2.0
        or else Generic_Value /= 3.5
        or else To_Native_Boolean (Data (3))
        or else To_Native_Small (Data (4)) /= 13
        or else To_Native_Shade (Data (5)) /= Blue
      then
         raise Program_Error with "witness assertion failed: copy-back values";
      end if;
   end Verify_Results;

   procedure Echo_String (Data : in out HAC_Element_Array) is
   begin
      if To_Native (Data (1)) /= "HAC text" then
         raise Program_Error with "witness assertion failed: string input";
      end if;
      Data (1) := To_HAC ("Native text");
   end Echo_String;

   procedure Verify_String (Data : in out HAC_Element_Array) is
   begin
      if To_Native (Data (1)) /= "Native text" then
         raise Program_Error with "witness assertion failed: string copy-back";
      end if;
   end Verify_String;

   procedure Trigger_Type_Error (Data : in out HAC_Element_Array) is
      Value : Long_Float;
   begin
      Value := To_Native (Data (1));
      Put_Line (Long_Float'Image (Value));
   end Trigger_Type_Error;

   procedure Trigger_Range_Error (Data : in out HAC_Element_Array) is
      Value : constant Small_Integer := To_Native_Small (Data (1));
   begin
      Put_Line (Small_Integer'Image (Value));
   end Trigger_Range_Error;

   procedure Trigger_Native_Error (Data : in out HAC_Element_Array) is
   begin
      raise Program_Error with "witness native failure";
   end Trigger_Native_Error;

   procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
   begin
      Register (BD, Say'Access, "Witness_API.Say");
      Register (BD, Secondary_Say'Access, "Witness_Secondary_API.Say");
      Register (BD, Sum_Callback'Access, "Witness_API.Sum_Callback");
      Register (BD, Verify_Integer'Access, "Witness_API.Verify_Integer");
      Register (BD, Check_Values'Access, "Witness_API.Check_Values");
      Register (BD, Verify_Results'Access, "Witness_API.Verify_Results");
      Register (BD, Echo_String'Access, "Witness_API.Echo_String");
      Register (BD, Verify_String'Access, "Witness_API.Verify_String");
      Register (BD, Trigger_Type_Error'Access, "Witness_API.Trigger_Type_Error");
      Register (BD, Trigger_Range_Error'Access, "Witness_API.Trigger_Range_Error");
      Register (BD, Trigger_Native_Error'Access, "Witness_API.Trigger_Native_Error");
   end Register_All;

end Witness_Native;
