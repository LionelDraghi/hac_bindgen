--
-- ARM 3.5.9 Fixed Point Types
--
-- Success: 13:1..23:32 Tree *
--
-- package ARM_3_5_9.Fixed_Point_Types is
--    type Volt is delta 0.125 range 0.0..255.0;
--    type Fraction is delta System.Fine_Delta range -(1.0)..1.0;
--    type Money is delta 0.01 digits 15;
--    subtype Salary is Money digits 10;
-- end ARM_3_5_9.Fixed_Point_Types;
--
package ARM_3_5_9.Fixed_Point_Types is
   type Volt is delta 0.125 range 0.0 .. 255.0;
      -- A pure fraction which requires all the available
      -- space in a word can be declared as the type Fraction:
   type Fraction is delta System.Fine_Delta range -1.0 .. 1.0;
      -- Fraction'Last = 1.0 – System.Fine_Delta

   type Money is delta 0.01 digits 15;  -- decimal fixed point
   subtype Salary is Money digits 10;
      -- Money'Last = 10.0**13 – 0.01, Salary'Last = 10.0**8 – 0.01
end ARM_3_5_9.Fixed_Point_Types;