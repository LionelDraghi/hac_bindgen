--
-- ARM 3.9_4(21-25) Interface Types
--
-- Success: 32:1..59:14 Tree *
--
-- package body ARM_3_9_4 is
--    type Queue is limited interface;
--    procedure Append (Q : in out Queue; Person : Person_Name) is abstract;
--    procedure Remove_First (Q      : in out Queue;
--                           Person :    out Person_Name) is abstract;
--    function Cur_Count (Q : Queue) return Natural is abstract;
--    function Max_Count (Q : Queue) return Natural is abstract;
--    Queue_Error : exception;
--    type Synchronized_Queue is
--                          synchronized interface and Queue;
--    procedure Append_Wait (Q      : in out Synchronized_Queue;
--                          Person :      Person_Name) is abstract;
--    procedure Remove_First_Wait (Q      : in out Synchronized_Queue;
--                                Person :    out Person_Name) is abstract;
--    procedure Transfer (From   : in out Queue'Class;
--                       To     : in out Queue'Class;
--                       Number :      Natural := 1) is
--       Person : Person_Name;
--    begin
--       for I in 1..Number loop
--          Remove_First (From, Person);
--          Append (To, Person);
--       end loop;
--    end Transfer;
-- end ARM_3_9_4;
--
package body ARM_3_9_4 is
   type Queue is limited interface;
   procedure Append(Q : in out Queue; Person : in Person_Name) is abstract;
   procedure Remove_First(Q      : in out Queue;
                          Person :    out Person_Name) is abstract;
   function Cur_Count(Q : in Queue) return Natural is abstract;
   function Max_Count(Q : in Queue) return Natural is abstract;
   -- See 3.10.1 for Person_Name.
   Queue_Error : exception;
   -- Append raises Queue_Error if Cur_Count(Q) = Max_Count(Q)
   -- Remove_First raises Queue_Error if Cur_Count(Q) = 0
   type Synchronized_Queue is
                         synchronized interface and Queue; -- see 9.11
   procedure Append_Wait(Q      : in out Synchronized_Queue;
                         Person : in     Person_Name) is abstract;
   procedure Remove_First_Wait(Q      : in out Synchronized_Queue;
                               Person :    out Person_Name) is abstract;
   procedure Transfer(From   : in out Queue'Class;
                      To     : in out Queue'Class;
                      Number : in     Natural := 1) is
      Person : Person_Name;
   begin
      for I in 1..Number loop
         Remove_First(From, Person);
         Append(To, Person);
      end loop;
   end Transfer;
end ARM_3_9_4;