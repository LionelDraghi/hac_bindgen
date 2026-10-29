--
-- ARM 3.5.4 Integer Types
--
-- Success: 18:1..28:28 Tree *
--
-- package ARM_3_5_4.Integer_Types is
--    type Page_Num  is range 1..2000;
--    type Line_Size is range 1..Max_Line_Size;
-- 
--    subtype Small_Int   is Integer   range -(10)..10;
--    subtype Column_Ptr  is Line_Size range 1..10;
--    subtype Buffer_Size is Integer   range 0..Max;
-- 
--    type Byte        is mod 256;
--    type Hash_Index  is mod 97;
-- end ARM_3_5_4.Integer_Types;
--
package ARM_3_5_4.Integer_Types is
   type Page_Num  is range 1 .. 2_000;
   type Line_Size is range 1 .. Max_Line_Size;

   subtype Small_Int   is Integer   range -10 .. 10;
   subtype Column_Ptr  is Line_Size range 1 .. 10;
   subtype Buffer_Size is Integer   range 0 .. Max;

   type Byte        is mod 256; -- an unsigned byte
   type Hash_Index  is mod 97;  -- modulus is prime
end ARM_3_5_4.Integer_Types;