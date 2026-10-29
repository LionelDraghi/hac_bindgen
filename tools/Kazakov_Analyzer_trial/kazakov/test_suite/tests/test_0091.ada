--
-- ARM 8.3.1 Overriding Indicators
--
-- Success: 20:1..37:14 Tree *
--
-- package ARM_8_3_1 is
--    type Security_Queue is new Queue with null record;
--    overriding
--    procedure Append (Q : in out Security_Queue; Person : Person_Name);
--    overriding
--    procedure Remove_First (Q : in out Security_Queue; Person : out Person_Name);
--    overriding
--    function Cur_Count (Q : Security_Queue) return Natural;
--    overriding
--    function Max_Count (Q : Security_Queue) return Natural;
--    not overriding
--    procedure Arrest (Q : in out Security_Queue; Person : Person_Name);
-- end ARM_8_3_1;
--
package ARM_8_3_1 is
   type Security_Queue is new Queue with null record;

   overriding
   procedure Append(Q : in out Security_Queue; Person : in Person_Name);

   overriding
   procedure Remove_First(Q : in out Security_Queue; Person : out Person_Name);

   overriding
   function Cur_Count(Q : in Security_Queue) return Natural;

   overriding
   function Max_Count(Q : in Security_Queue) return Natural;

   not overriding
   procedure Arrest(Q : in out Security_Queue; Person : in Person_Name);
end ARM_8_3_1;