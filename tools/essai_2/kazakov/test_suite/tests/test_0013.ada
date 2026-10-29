--
-- ARM 3.3.2 Number Declarations
--
-- Success: 16:1..24:34 Tree *
--
-- with Ada.Numerics;
-- package ARM_3_3_2.Number_Declarations is
--    Two_Pi        : constant := (2.0 * Ada.Numerics.Pi);
--    Max           : constant := 500;
--    Max_Line_Size : constant := (Max / 6);
--    Power_16      : constant := (2 ** 16);
--    One, Un, Eins : constant := 1;
-- end ARM_3_3_2.Number_Declarations;
--
with Ada.Numerics;
package ARM_3_3_2.Number_Declarations is
   Two_Pi        : constant := 2.0*Ada.Numerics.Pi; 
                                          -- a real number (see A.5)
   Max           : constant := 500;       -- an integer number
   Max_Line_Size : constant := Max/6;     -- the integer 83
   Power_16      : constant := 2**16;     -- the integer 65_536
   One, Un, Eins : constant := 1;         -- three different names for 1

end ARM_3_3_2.Number_Declarations;