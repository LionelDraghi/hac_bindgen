--
-- ARM 9.7.1 Selective Accept
--
-- Success: 26:1..44:14 Tree *
--
-- package body ARM_9_7_1 is
--    task body Server is
--       Current_Work_Item : Work_Item;
--    begin
--       loop
--          select
--             accept Next_Work_Item (WI : Work_Item) do
--                Current_Work_Item := WI;
--             end Next_Work_Item;
--             Process_Work_Item (Current_Work_Item);
--          or
--             accept Shut_Down;
--             exit;
--          or
--             terminate;
--          end select;
--       end loop;
--    end Server;
-- end ARM_9_7_1;
--
package body ARM_9_7_1 is
   task body Server is
      Current_Work_Item : Work_Item;
   begin
      loop
         select
            accept Next_Work_Item(WI : in Work_Item) do
               Current_Work_Item := WI;
            end;
            Process_Work_Item(Current_Work_Item);
         or
            accept Shut_Down;
            exit;       -- Premature shut down requested
         or
            terminate;  -- Normal shutdown at end of scope
         end select;
      end loop;
   end Server;
end ARM_9_7_1;