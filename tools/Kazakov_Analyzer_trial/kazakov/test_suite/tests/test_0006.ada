--
-- ARM 3.2.1 Type declaration
--
-- Success: 12:1..16:32 Tree *
--
-- package ARM_3_2_1.Type_Declarations is
--    type Color is (White, Red, Yellow, Green, Blue, Brown, Black);
--    type Column is range 1..72;
--    type Table is array (1..10) of Integer;
-- end ARM_3_2_1.Type_Declarations;
--
package ARM_3_2_1.Type_Declarations is
   type Color  is (White, Red, Yellow, Green, Blue, Brown, Black);
   type Column is range 1 .. 72;
   type Table  is array(1 .. 10) of Integer;
end ARM_3_2_1.Type_Declarations;