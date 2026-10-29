--
-- ARM 3.8 Record Types
--
-- Success: 22:1..39:25 Tree *
--
-- package ARM_3_8.Record_Types is
--    type Date is
--       record
--          Day   : Integer range 1..31;
--          Month : Month_Name;
--          Year  : Integer range 0..4000;
--       end record;
--    type Complex is
--       record
--          Re : Real := 0.0;
--          Im : Real := 0.0;
--       end record;
--    Tomorrow, Yesterday : Date;
--    A, B, C : Complex;
-- end ARM_3_8.Record_Types;
--
package ARM_3_8.Record_Types is
   type Date is
      record
         Day   : Integer range 1 .. 31;
         Month : Month_Name;                  -- see 3.5.1
         Year  : Integer range 0 .. 4000;
      end record;

   type Complex is
      record
         Re : Real := 0.0;
         Im : Real := 0.0;
      end record Complex;

   Tomorrow, Yesterday : Date;
   A, B, C : Complex;

end ARM_3_8.Record_Types;