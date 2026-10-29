--
-- ARM 8.4(14-16) Use Clauses
--
-- Success: 13:1..16:12 Tree *
--
-- with Ada.Calendar; use Ada;
-- package ARM_8_4 is
--    use type Rational_Numbers.Rational;
--    Two_Thirds : Rational_Numbers.Rational := (2 / 3);
-- end ARM_8_4;
--
with Ada.Calendar; use Ada;
package ARM_8_4 is
   use type Rational_Numbers.Rational; -- see 7.1
   Two_Thirds: Rational_Numbers.Rational := 2/3;
end ARM_8_4;