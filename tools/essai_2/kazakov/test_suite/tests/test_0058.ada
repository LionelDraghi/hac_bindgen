--
-- ARM 5.3 If Statements
--
-- Success: 26:1..46:12 Tree *
--
-- package body ARM_5_3 is
-- begin
--    if ((Month = December) and (Day = 31)) then
--       Month := January;
--       Day   := 1;
--       Year  := (Year + 1);
--    end if;
--    if Line_Too_Short then
--       raise Layout_Error;
--    elsif Line_Full then
--       New_Line;
--       Put (Item);
--    else
--       Put (Item);
--    end if;
--    if (My_Car.Owner.Vehicle /= My_Car) then
--       Report ("Incorrect data");
--    end if;
-- end ARM_5_3;
--
package body ARM_5_3 is
begin
   if Month = December and Day = 31 then
      Month := January;
      Day   := 1;
      Year  := Year + 1;
   end if;

   if Line_Too_Short then
      raise Layout_Error;
   elsif Line_Full then
      New_Line;
      Put(Item);
   else
      Put(Item);
   end if;

   if My_Car.Owner.Vehicle /= My_Car then            -- see 3.10.1
      Report ("Incorrect data");
   end if;
end ARM_5_3;