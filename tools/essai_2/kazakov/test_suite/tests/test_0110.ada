--
-- ARM 9.7 Select Statements
--
-- Success: 18:1..30:12 Tree *
--
-- package body ARM_9_7 is
--    task body T is
--    begin
--       select
--          accept Driver_Awake_Signal;
--       or
--          delay (30.0 * Seconds);
--          Stop_The_Train;
--       end select;
--    end T;
-- end ARM_9_7;
--
package body ARM_9_7 is

   task body T is
   begin
      select
         accept Driver_Awake_Signal;
      or
         delay 30.0*Seconds;
         Stop_The_Train;
      end select;
   end T;

end ARM_9_7;