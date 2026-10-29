--
-- ARM 7.3.2(36-41) Type Invariants
--
-- Success: 27:1..52:16 Tree *
--
-- package body Work_Orders is
--    function Schedule_Work (Urgency  : Level;
--                            To_Occur : Day) return Work_Order is
--      ((Scheduled => To_Occur, Urgency => Urgency));
--    function Day_Scheduled (Order : Work_Order) return Day is
--      (Order.Scheduled);
--    function Priority (Order : Work_Order) return Level is
--      (Order.Urgency);
--    procedure Change_Priority (Order        : in out Work_Order;
--                               New_Priority :      Level;
--                               Changed      : out    Boolean) is
--    begin
--       if ((Order.Urgency = Urgent) or else Order.Scheduled in Weekday) then
--          Changed := True;
--          Order.Urgency := New_Priority;
--       else
--          Changed := False;
--       end if;
--    end Change_Priority;
-- end Work_Orders;
--
package body Work_Orders is

   function Schedule_Work (Urgency  : in Level;
                           To_Occur : in Day) return Work_Order is
     (Scheduled => To_Occur, Urgency => Urgency);

   function Day_Scheduled (Order : in Work_Order) return Day is
     (Order.Scheduled);

   function Priority (Order : in Work_Order) return Level is
     (Order.Urgency);

   procedure Change_Priority (Order        : in out Work_Order;
                              New_Priority : in     Level;
                              Changed      : out    Boolean) is
   begin
      -- Ensure type invariant is not violated
      if Order.Urgency = Urgent or else (Order.Scheduled in Weekday) then
         Changed := True;
         Order.Urgency := New_Priority;
      else
         Changed := False;
      end if;
   end Change_Priority;

end Work_Orders;