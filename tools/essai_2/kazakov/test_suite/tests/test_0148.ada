--
-- Selective accept https://en.wikibooks.org/wiki/Ada_Programming/Tasking Ex.8
--
-- Success: 40:1..74:9
--
-- procedure WiKi is
--   subtype Buffer_Id is Integer range 1..nr_Bufs;
--   task Buffer_Pool_Task is
--      entry Insert (Buffer_Id) (An_Item : Item);
--      entry Remove (Buffer_Id) (An_Item : out Item);
--   end Buffer_Pool_Task;
--   task body Buffer_Pool_Task is
--      Data   : array (Buffer_Id) of Item;
--      Filled : array (Buffer_Id) of Boolean  := (others => False);
--   begin
--     loop
--       for I in Data'Range loop
--         select
--           when not (Filled (I)) =>
--              accept Insert (I) (An_Item : Item) do
--                 Data (I) := An_Item;
--              end Insert;
--              Filled (I) := True;
--         or
--           when Filled (I) =>
--              accept Remove (I) (An_Item : out Item) do
--                     An_Item := Data (I);
--              end Remove;
--              Filled (I) := False;
--         else
--           null;
--         end select;
--       end loop;
--     end loop;   
--   end Buffer_Pool_Task;
-- begin
--   Buffer_Pool_Task.Remove (K) (This_Item);
-- end WiKi;
--
procedure WiKi is
  subtype Buffer_Id is Integer range 1 .. nr_Bufs;

  task Buffer_Pool_Task is
     entry Insert (Buffer_Id) (An_Item : in Item);
     entry Remove (Buffer_Id) (An_Item : out Item);
  end Buffer_Pool_Task;

  task body Buffer_Pool_Task is
     Data   : array (Buffer_Id) of Item;
     Filled : array (Buffer_Id) of Boolean  := (others => False);
  begin
    loop
      for I in Data'Range loop
        select
          when not Filled(I) =>
             accept Insert (I) (An_Item : in Item) do
                Data(I) := An_Item;
             end Insert;
             Filled(I) := True;
        or
          when Filled(I) =>
             accept Remove (I) (An_Item : out Item) do
                    An_Item := Data(I);
             end Remove;
             Filled(I) := False;
        else
          null; -- N.B. "polling" or "busy waiting"
        end select;
      end loop;
    end loop;   
  end Buffer_Pool_Task;
begin
  Buffer_Pool_Task.Remove(K)(This_Item);
end WiKi;