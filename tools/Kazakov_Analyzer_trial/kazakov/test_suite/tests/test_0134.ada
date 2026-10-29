--
-- ARM 13.4 Enumeration Representation Clauses
--
-- Success: 13:1..27:13 Tree *
--
-- package ARM_13_4 is
--    type Mix_Code is (ADD, SUB, MUL, LDA, STA, STZ);
--    for Mix_Code use
--       (ADD => 1, SUB => 2, MUL => 3, LDA => 8, STA => 24, STZ => 33);
--    for Roman_Digit use ('I' => 1, 'V' => 5, 'X' => 10, 'L' => 50, 'C' => 100, 'D' => 500, 'M' => 1000);
-- end ARM_13_4;
--
package ARM_13_4 is
   type Mix_Code is (ADD, SUB, MUL, LDA, STA, STZ);

   for Mix_Code use
      (ADD => 1, SUB => 2, MUL => 3, LDA => 8, STA => 24, STZ =>33);

   -- See 3.5.2.
   for Roman_Digit use ('I' => 1,
                        'V' => 5,
                        'X' => 10,
                        'L' => 50,
                        'C' => 100,
                        'D' => 500,
                        'M' => 1000);
end ARM_13_4;