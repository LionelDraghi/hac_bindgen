--
-- ARM 3.10.2(41) Operations of Access Types
--
-- Success: 14:1..20:15 Tree *
--
-- procedure ARM_3_10_2 is
--    Becky  : Person_Name := new (Person (F));
--    Cars   : array (1..2) of aliased Car;
-- begin
--    Becky.Vehicle := Cars (1)'Access;
--    Casey.Vehicle := Cars (2)'Access;
-- end ARM_3_10_2;
--
procedure ARM_3_10_2 is
   Becky  : Person_Name := new Person(F);       -- see 3.10.1
   Cars   : array (1..2) of aliased Car;
begin
   Becky.Vehicle := Cars(1)'Access;
   Casey.Vehicle := Cars(2)'Access;
end ARM_3_10_2;