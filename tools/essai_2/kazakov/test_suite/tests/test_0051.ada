--
-- ARM 4.5.10(42) Reduction Expressions
--
-- Success: 14:1..22:15
--
-- package ARM_4_5_10 is
--    function Pi (Number_Of_Steps : Natural := 10000) return Real is
--      ((1.0 / Real (Number_Of_Steps) /
--          ⅟([for I in 1..Number_Of_Steps =>
--            (4.0 / (1.0 + (((Real (I) - 0.5) *
--               (1.0 / Real (Number_Of_Steps))) ** 2)))]'Reduce ("+", 0.0))));
-- end ARM_4_5_10;
--
package ARM_4_5_10 is
   --  See 3.5.7.
   function Pi (Number_Of_Steps : Natural := 10_000) return Real is
     (1.0 / Real (Number_Of_Steps) *
        [for I in 1 .. Number_Of_Steps =>
           (4.0 / (1.0 + ((Real (I) - 0.5) *
              (1.0 / Real (Number_Of_Steps)))**2))]
                 'Reduce("+", 0.0));
end ARM_4_5_10;