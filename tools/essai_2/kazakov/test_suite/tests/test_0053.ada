--
-- ARM 4.6(66-68) Type Conversions
--
-- Success: 15:1..23:12
--
-- package body ARM_4_6 is
--    type A_Form is new B_Form;
--    X : A_Form;
--    Y : B_Form;
-- begin
--    X := A_Form (Y);
--    Y := B_Form (X);
-- end ARM_4_6;
--
package body ARM_4_6 is
   type A_Form is new B_Form;

   X : A_Form;
   Y : B_Form;
begin
   X := A_Form(Y);
   Y := B_Form(X);  --  the reverse conversion 
end ARM_4_6;