--
-- ARM 4.5.10(40) Reduction Expressions
--
-- Success: 12:1..16:15
--
-- procedure ARM_4_5_10 is
-- begin
--    Put_Line (("Sum of Squares is" &
--           Integer'Image ([for I in 1..10 => (I ** 2)]'Reduce ("+", 0))));
-- end ARM_4_5_10;
--
procedure ARM_4_5_10 is
begin
   Put_Line ("Sum of Squares is" &
          Integer'Image([for I in 1 .. 10 => I**2]'Reduce("+", 0)));
end ARM_4_5_10;