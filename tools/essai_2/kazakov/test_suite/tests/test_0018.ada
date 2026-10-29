--
-- ARM 3.5.7 Floating Point Types
--
-- Success: 13:1..21:35 Tree *
--
-- package ARM_3_5_7.Floating_Point_Types is
--    type Coefficient is digits 10 range -(1.0)..1.0;
--    type Real is digits 8;
--    type Mass is digits 7 range 0.0..1.0E35;
--    subtype Probability is Real range 0.0..1.0;
-- end ARM_3_5_7.Floating_Point_Types;
--
package ARM_3_5_7.Floating_Point_Types is
   type Coefficient is digits 10 range -1.0 .. 1.0;

   type Real is digits 8;
   type Mass is digits 7 range 0.0 .. 1.0E35;

   subtype Probability is Real range 0.0 .. 1.0;
       -- a subtype with a smaller range
end ARM_3_5_7.Floating_Point_Types;