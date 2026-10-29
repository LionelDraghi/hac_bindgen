--
-- ARM 9.6(38-40) Delay Statements, Duration, and Time
--
-- Success: 20:1..35:12 Tree *
--
-- package body ARM_9_6 is
-- begin
--    delay 3.0;
--    declare
--       use Ada.Calendar;
--       Next_Time : Time := (Clock + Period);
--    begin
--       loop
--          delay until Next_Time;
--          Next_Time := (Next_Time + Period);
--       end loop;
--    end;
-- end ARM_9_6;
--
package body ARM_9_6 is
begin
   delay 3.0;  -- delay 3.0 seconds

   declare
      use Ada.Calendar;
      Next_Time : Time := Clock + Period;
                         -- Period is a global constant of type Duration
   begin
      loop               -- repeated every Period seconds
         delay until Next_Time;
         -- perform some actions
         Next_Time := Next_Time + Period;
      end loop;
   end;
end ARM_9_6;