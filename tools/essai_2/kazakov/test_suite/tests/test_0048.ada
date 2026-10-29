--
-- ARM 4.5.10(36) Reduction Expressions
--
-- Success: 11:1..14:15 Tree *
--
-- package ARM_4_5_10 is
--    function Factorial (N : Natural) return Natural is
--       ([for J in 1..N => J]'Reduce ("*", 1));
-- end ARM_4_5_10;
--
package ARM_4_5_10 is
   function Factorial(N : Natural) return Natural is
      ([for J in 1..N => J]'Reduce("*", 1));
end ARM_4_5_10;