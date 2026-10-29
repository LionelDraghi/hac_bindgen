--
-- ARM 9.7.4 Asynchronous Transfer of Control
--
-- Success: 26:1..48:14 Tree *
--
-- procedure ARM_9_7_4 is
-- begin
--    loop
--       select
--          Terminal.Wait_For_Interrupt;
--          Put_Line ("Interrupted");
--       then abort
--          Put_Line ("-> ");
--          Get_Line (Command, Last);
--          Process_Command (Command (1..Last));
--       end select;
--    end loop;
--    select
--       delay 5.0;
--       Put_Line ("Calculation does not converge");
--    then abort
--       Horribly_Complicated_Recursive_Function (X, Y);
--    end select;
-- end ARM_9_7_4;
--
procedure ARM_9_7_4 is
begin
   loop
      select
         Terminal.Wait_For_Interrupt;
         Put_Line("Interrupted");
      then abort
         -- This will be abandoned upon terminal interrupt
         Put_Line("-> ");
         Get_Line(Command, Last);
         Process_Command(Command(1..Last));
      end select;
   end loop;

   select
      delay 5.0;
      Put_Line("Calculation does not converge");
   then abort
      -- This calculation is expected to should finish in 5.0 seconds;
      --  if not, it is assumed to diverge.
      Horribly_Complicated_Recursive_Function(X, Y);
   end select;
end ARM_9_7_4;