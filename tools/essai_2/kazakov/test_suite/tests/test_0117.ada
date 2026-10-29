--
-- ARM 9.11(7-13) Example of Tasking and Synchronization
--
-- Success: 61:1..123:13 Tree *
--
-- package body ARM_9_11 is
--    type Person_Name_Array is array (Positive range <>)
--       of Person_Name;
--    protected Buffer is new Synchronized_Queue with
--       entry Append_Wait (Person : Person_Name);
--       entry Remove_First_Wait (Person : out Person_Name);
--       function Cur_Count return Natural;
--       function Max_Count return Natural;
--       procedure Append (Person : Person_Name);
--       procedure Remove_First (Person : out Person_Name);
--    private
--       Pool      : Person_Name_Array (1..100);
--       Count     : Natural := 0;
--       In_Index, Out_Index : Positive := 1;
--    end Buffer;
--    protected body Buffer is
--       entry Append_Wait (Person : Person_Name)
--          when (Count < Pool'Length) is
--       begin
--          Append (Person);
--       end Append_Wait;
--       procedure Append (Person : Person_Name) is
--       begin
--          if (Count = Pool'Length) then
--             raise Queue_Error with "Buffer Full";
--          end if;
--          Pool (In_Index) := Person;
--          In_Index       := ((In_Index mod Pool'Length) + 1);
--          Count          := (Count + 1);
--       end Append;
--       entry Remove_First_Wait (Person : out Person_Name)
--          when (Count > 0) is
--       begin
--          Remove_First (Person);
--       end Remove_First_Wait;
--       procedure Remove_First (Person : out Person_Name) is
--       begin
--          if (Count = 0) then
--             raise Queue_Error with "Buffer Empty";
--          end if;
--          Person    := Pool (Out_Index);
--          Out_Index := ((Out_Index mod Pool'Length) + 1);
--          Count     := (Count - 1);
--       end Remove_First;
--       function Cur_Count return Natural is
--       begin
--           return Buffer.Count;
--       end Cur_Count;
--       function Max_Count return Natural is
--       begin
--           return Pool'Length;
--       end Max_Count;
--    end Buffer;
-- end ARM_9_11;
--
package body ARM_9_11 is

   type Person_Name_Array is array (Positive range <>)
      of Person_Name;  -- see 3.10.1

   protected Buffer is new Synchronized_Queue with  -- see 3.9.4
      entry Append_Wait(Person : in Person_Name);
      entry Remove_First_Wait(Person : out Person_Name);
      function Cur_Count return Natural;
      function Max_Count return Natural;
      procedure Append(Person : in Person_Name);
      procedure Remove_First(Person : out Person_Name);
   private
      Pool      : Person_Name_Array(1 .. 100);
      Count     : Natural := 0;
      In_Index, Out_Index : Positive := 1;
   end Buffer;

   protected body Buffer is
      entry Append_Wait(Person : in Person_Name)
         when Count < Pool'Length is
      begin
         Append(Person);
      end Append_Wait;

      procedure Append(Person : in Person_Name) is
      begin
         if Count = Pool'Length then
            raise Queue_Error with "Buffer Full";  -- see 11.3
         end if;
         Pool(In_Index) := Person;
         In_Index       := (In_Index mod Pool'Length) + 1;
         Count          := Count + 1;
      end Append;

      entry Remove_First_Wait(Person : out Person_Name)
         when Count > 0 is
      begin
         Remove_First(Person);
      end Remove_First_Wait;

      procedure Remove_First(Person : out Person_Name) is
      begin
         if Count = 0 then
            raise Queue_Error with "Buffer Empty"; -- see 11.3
         end if;
         Person    := Pool(Out_Index);
         Out_Index := (Out_Index mod Pool'Length) + 1;
         Count     := Count - 1;
      end Remove_First;

      function Cur_Count return Natural is
      begin
          return Buffer.Count;
      end Cur_Count;

      function Max_Count return Natural is
      begin
          return Pool'Length;
      end Max_Count;
   end Buffer;

end ARM_9_11;