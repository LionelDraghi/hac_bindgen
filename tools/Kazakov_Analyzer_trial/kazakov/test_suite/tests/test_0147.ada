--
-- Protected object https://en.wikibooks.org/wiki/Ada_Programming/Tasking Ex.7
--
-- Success: 33:1..59:9
--
-- procedure WiKi is
--   protected type Semaphore_Protected_Type is
--      procedure Initialize (N : Natural);
--      entry Wait;
--      procedure Signal;
--   private
--      Count : Natural := 0;
--   end Semaphore_Protected_Type;
--   protected body Semaphore_Protected_Type is
--      procedure Initialize (N : Natural) is
--      begin
--         Count := N;
--      end Initialize;
--      entry Wait
--         when (Count > 0) is
--      begin
--         Count := (Count - 1);
--      end Wait;
--      procedure Signal is
--      begin
--         Count := (Count + 1);
--      end Signal;
--   end Semaphore_Protected_Type;
-- begin
--   null;
-- end WiKi;
--
procedure WiKi is
  protected type Semaphore_Protected_Type is
     procedure Initialize (N : in Natural);
     entry Wait;
     procedure Signal;
  private
     Count : Natural := 0;
  end Semaphore_Protected_Type;
  
  protected body Semaphore_Protected_Type is
     procedure Initialize (N : in Natural) is
     begin
        Count := N;
     end Initialize;
     entry Wait
        when Count > 0 is
     begin
        Count := Count - 1;
     end Wait;
     procedure Signal is
     begin
        Count := Count + 1;
     end Signal;
  end Semaphore_Protected_Type;
begin
  null;
end WiKi;