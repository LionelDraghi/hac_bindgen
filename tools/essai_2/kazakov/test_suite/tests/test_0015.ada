--
-- ARM 3.5.1 Enumeration Types
--
-- Success: 24:1..41:32 Tree *
--
-- package ARM_3_5_1.Enumeration_Types is
--    type Day        is (Mon, Tue, Wed, Thu, Fri, Sat, Sun);
--    type Month_Name is (January, February, March, April, May, June, July,
--                     August, September, October, November, December);
--    type Suit       is (Clubs, Diamonds, Hearts, Spades);
--    type Gender     is (M, F);
--    type Level      is (Low, Medium, Urgent);
--    type Color      is (White, Red, Yellow, Green, Blue, Brown, Black);
--    type Light      is (Red, Amber, Green);
-- 
--    type Hexa       is ('A', 'B', 'C', 'D', 'E', 'F');
--    type Mixed      is ('A', 'B', '*', B, None, '?', '%');
-- 
--    subtype Weekday is Day   range Mon..Fri;
--    subtype Major   is Suit  range Hearts..Spades;
--    subtype Rainbow is Color range Red..Blue;
-- end ARM_3_5_1.Enumeration_Types;
--
package ARM_3_5_1.Enumeration_Types is
   type Day        is (Mon, Tue, Wed, Thu, Fri, Sat, Sun);
   type Month_Name is (January, February, March, April, May, June, July,
                    August, September, October, November, December);
   type Suit       is (Clubs, Diamonds, Hearts, Spades);
   type Gender     is (M, F);
   type Level      is (Low, Medium, Urgent);
   type Color      is (White, Red, Yellow, Green, Blue, Brown, Black);
   type Light      is (Red, Amber, Green); -- Red and Green are overloaded

   type Hexa       is ('A', 'B', 'C', 'D', 'E', 'F');
   type Mixed      is ('A', 'B', '*', B, None, '?', '%');

   subtype Weekday is Day   range Mon .. Fri;
   subtype Major   is Suit  range Hearts .. Spades;
   subtype Rainbow is Color range Red .. Blue;
                               -- the Color Red, not the Light
end ARM_3_5_1.Enumeration_Types;