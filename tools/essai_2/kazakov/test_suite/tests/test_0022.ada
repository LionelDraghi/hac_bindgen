--
-- ARM 3.6.3 String Types
--
-- Success: 14:1..23:27 Tree *
--
-- package ARM_3_6_3.String_Types is
--    Stars      : String (1..120) := (1..120 => '*');
--    Question   : constant String  := "How many characters?";
-- 
--    Ask_Twice  : String  := (Question & Question);
--    Ninety_Six : constant Roman   := "XCVI";
-- end ARM_3_6_3.String_Types;
--
package ARM_3_6_3.String_Types is
   Stars      : String(1 .. 120) := (1 .. 120 => '*' );
   Question   : constant String  := "How many characters?";
                      -- Question'First = 1, Question'Last = 20
                      -- Question'Length = 20 (the number of characters)

   Ask_Twice  : String  := Question & Question; -- constrained to (1..40)
   Ninety_Six : constant Roman   := "XCVI";     -- see 3.5.2 and 3.6

end ARM_3_6_3.String_Types;