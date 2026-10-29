--
-- ARM 3.9_4(29-30) Interface Types
--
-- Success: 19:1..33:14 Tree *
--
-- package body ARM_3_9_4 is
--    type Fast_Food_Queue is new Queue with record P : Integer; end record;
--    procedure Append (Q : in out Fast_Food_Queue; Person : Person_Name);
--    procedure Remove_First (Q : in out Fast_Food_Queue; 
--                           Person : out Person_Name);
--    function Cur_Count (Q : Fast_Food_Queue) return Natural;
--    function Max_Count (Q : Fast_Food_Queue) return Natural;
--    Cashier, Counter : Fast_Food_Queue;
-- begin
--    Append (Cashier, Casey);
--    Transfer (Cashier, Counter);
-- end ARM_3_9_4;
--
package body ARM_3_9_4 is
   type Fast_Food_Queue is new Queue with record P : Integer; end record;
   procedure Append(Q : in out Fast_Food_Queue; Person : in Person_Name);
   procedure Remove_First(Q : in out Fast_Food_Queue; 
                          Person : out Person_Name);
   function Cur_Count(Q : in Fast_Food_Queue) return Natural;
   function Max_Count(Q : in Fast_Food_Queue) return Natural;

   Cashier, Counter : Fast_Food_Queue;
begin
      -- Add Casey George (see 3.10.1) to the cashier's queue:
   Append (Cashier, Casey);
      -- After payment, move Casey to the sandwich counter queue:
   Transfer (Cashier, Counter);
end ARM_3_9_4;