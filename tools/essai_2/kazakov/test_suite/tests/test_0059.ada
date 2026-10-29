--
-- ARM 5.4 Case Statements
--
-- Success: 30:1..54:12 Tree *
--
-- package body ARM_5_4 is
-- begin
--    case Sensor is
--       when Elevation      => Record_Elevation (Sensor_Value);
--       when Azimuth        => Record_Azimuth  (Sensor_Value);
--       when Distance       => Record_Distance (Sensor_Value);
--       when others         => null;
--    end case;
--    case Today is
--       when Mon            => Compute_Initial_Balance;
--       when Fri            => Compute_Closing_Balance;
--       when Tue..Thu     => Generate_Report (Today);
--       when Sat..Sun     => null;
--    end case;
--    case Bin_Number (Count) is
--       when 1        => Update_Bin (1);
--       when 2        => Update_Bin (2);
--       when 3 | 4    =>
--          Empty_Bin (1);
--          Empty_Bin (2);
--       when others   => raise Error;
--    end case;
-- end ARM_5_4;
--
package body ARM_5_4 is
begin
   case Sensor is
      when Elevation      => Record_Elevation(Sensor_Value);
      when Azimuth        => Record_Azimuth  (Sensor_Value);
      when Distance       => Record_Distance (Sensor_Value);
      when others         => null;
   end case;

   case Today is
      when Mon            => Compute_Initial_Balance;
      when Fri            => Compute_Closing_Balance;
      when Tue .. Thu     => Generate_Report(Today);
      when Sat .. Sun     => null;
   end case;

   case Bin_Number(Count) is
      when 1        => Update_Bin(1);
      when 2        => Update_Bin(2);
      when 3 | 4    =>
         Empty_Bin(1);
         Empty_Bin(2);
      when others   => raise Error;
   end case;
end ARM_5_4;