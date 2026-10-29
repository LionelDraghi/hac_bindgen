--
-- ARM 5.6 Block Statements
--
-- Success: 16:1..24:12 Tree *
--
-- package body ARM_5_6 is
-- begin
-- Swap :
--    declare
--       Temp : Integer;
--    begin
--       Temp := V; V := U; U := Temp;
--    end Swap;
-- end ARM_5_6;
--
package body ARM_5_6 is
begin
Swap:
   declare
      Temp : Integer;
   begin
      Temp := V; V := U; U := Temp;
   end Swap;
end ARM_5_6;