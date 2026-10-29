--
-- Task https://en.wikibooks.org/wiki/Ada_Programming/Tasking Ex.6
--
-- Success: 36:1..67:9
--
-- procedure WiKi is
--   task type Semaphore_Task_Type is
--      entry Initialize (N : Natural);
--      entry Wait;
--      entry Signal;
--   end Semaphore_Task_Type;
--   task body Semaphore_Task_Type is
--      Count : Natural;
--   begin
--      accept Initialize (N : Natural) do
--         Count := N;
--      end Initialize;
--      loop
--         select
--            when (Count > 0) =>
--                accept Wait do
--                   Count := (Count - 1);
--                end Wait;
--         or
--                accept Signal;
--                Count := (Count + 1);
--         end select;
--      end loop;
--   end Semaphore_Task_Type;
--    nr_Full, nr_Free : Semaphore_Task_Type;
-- begin
--   nr_Full.Initialize (0); nr_Free.Initialize (nr_Slots);
--   nr_Free.Wait; nr_Full.Signal;
-- end WiKi;
--
procedure WiKi is
  task type Semaphore_Task_Type is
     entry Initialize (N : in Natural);
     entry Wait;
     entry Signal;
  end Semaphore_Task_Type;

  task body Semaphore_Task_Type is
     Count : Natural;
  begin
     accept Initialize (N : in Natural) do
        Count := N;
     end Initialize;
     loop
        select
           when Count > 0 =>
               accept Wait do
                  Count := Count - 1;
               end Wait;
        or
               accept Signal;
               Count := Count + 1;
        end select;
     end loop;
  end Semaphore_Task_Type;

   nr_Full, nr_Free : Semaphore_Task_Type;
begin
  nr_Full.Initialize (0); nr_Free.Initialize (nr_Slots);
-- ...
  nr_Free.Wait; nr_Full.Signal;
end WiKi;
