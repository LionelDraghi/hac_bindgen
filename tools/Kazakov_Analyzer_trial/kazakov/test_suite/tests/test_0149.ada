--
-- Selective accept https://en.wikibooks.org/wiki/Ada_Programming/Tasking Ex.9
--
-- Success: 35:1..63:9
--
-- procedure WiKi is
--   task type Terminating_Buffer_Task_Type is
--      entry Insert (An_Item : Item);
--      entry Remove (An_Item : out Item);
--   end Terminating_Buffer_Task_Type;
--   task body Terminating_Buffer_Task_Type is
--      Datum : Item;
--   begin
--      loop
--         select
--            accept Insert (An_Item :   Item) do
--               Datum := An_Item;
--            end Insert;
--         or
--            terminate;
--         end select;
--         select
--            accept Remove (An_Item : out Item) do
--               An_Item := Datum;
--            end Remove;
--         or
--            terminate;
--         end select;
--      end loop;
--   end Terminating_Buffer_Task_Type;
-- begin
--   null;
-- end WiKi;
--
procedure WiKi is
  task type Terminating_Buffer_Task_Type is
     entry Insert (An_Item : in  Item);
     entry Remove (An_Item : out Item);
  end Terminating_Buffer_Task_Type;

  task body Terminating_Buffer_Task_Type is
     Datum : Item;
  begin
     loop
        select
           accept Insert (An_Item : in  Item) do
              Datum := An_Item;
           end Insert;
        or
           terminate;
        end select;
        select
           accept Remove (An_Item : out Item) do
              An_Item := Datum;
           end Remove;
        or
           terminate;
        end select;
     end loop;
  end Terminating_Buffer_Task_Type;
begin
  null;
end WiKi;