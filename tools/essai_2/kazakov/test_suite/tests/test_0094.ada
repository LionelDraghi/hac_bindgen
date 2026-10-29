--
-- ARM 8.5.1(8) Object Renaming Declarations
--
-- Success: 15:1..22:14 Tree *
--
-- package body ARM_8_5_1 is
-- begin
--    declare
--       L : Person renames Leftmost_Person;
--    begin
--       L.Age := (L.Age + 1);
--    end;
-- end ARM_8_5_1;
--
package body ARM_8_5_1 is
begin
   declare
      L : Person renames Leftmost_Person; -- see 3.10.1
   begin
      L.Age := L.Age + 1;
   end;
end ARM_8_5_1;