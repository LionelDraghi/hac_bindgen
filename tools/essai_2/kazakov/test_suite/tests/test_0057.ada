--
-- ARM 5.2.1 Target Name Symbols
--
-- Success: 14:1..25:14 Tree *
--
-- package body ARM_5_2_1 is
--    My_Complex_Array : array (1..Max) of Complex;
-- begin
--    Board (1, 1) := (@ + 1.0);
--    My_Complex_Array (Count) := (Re => ((@.Re ** 2) - (@.Im ** 2)),
--                                 Im => (2.0 * @.Re * @.Im));
-- end ARM_5_2_1;
--
package body ARM_5_2_1 is
   My_Complex_Array : array (1 .. Max) of Complex; -- See 3.3.2, 3.8.
   -- Square the element in the Count (see 3.3.1) position:
begin
   Board(1, 1) := @ + 1.0;
               -- An abbreviation for Board(1, 1) := Board(1, 1) + 1.0;
               -- (Board is declared in 3.6.1).
   My_Complex_Array (Count) := (Re => @.Re**2 - @.Im**2,
                                Im => 2.0 * @.Re * @.Im);
      -- A target_name can be used multiple times and
      -- as a prefix if desired.
end ARM_5_2_1;