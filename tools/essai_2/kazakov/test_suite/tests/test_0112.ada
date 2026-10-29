--
-- ARM 9.7.2 Timed Entry Calls
--
-- Success: 15:1..24:14 Tree *
--
-- procedure ARM_9_7_2 is
-- begin
--    select
--       Controller.Request (Medium) (Some_Item);
--    or
--       delay 45.0;
--    end select;
-- end ARM_9_7_2;
--
procedure ARM_9_7_2 is
begin
   select
      Controller.Request(Medium)(Some_Item);
   or
      delay 45.0;
      --  controller too busy, try something else
   end select;

end ARM_9_7_2;