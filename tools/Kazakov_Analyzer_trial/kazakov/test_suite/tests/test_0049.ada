--
-- ARM 4.5.10(38) Reduction Expressions
--
-- Success: 13:1..18:15
--
-- package ARM_4_5_10 is
--    function Sine (X : Float; Num_Terms : Positive := 5) return Float is
--       ([for I in 1..Num_Terms =>
--          ((-(1.0) ** (I - 1)) * (X ** ((2 * I) - 1)) *
--             ⅟(Float (Factorial (((2 * I) - 1)))))]'Reduce ("+", 0.0));
-- end ARM_4_5_10;
--
package ARM_4_5_10 is
   function Sine (X : Float; Num_Terms : Positive := 5) return Float is
      ([for I in 1..Num_Terms =>
         (-1.0)**(I-1) * X**(2*I-1)/Float(Factorial(2*I-1))]
            'Reduce("+", 0.0));
end ARM_4_5_10;