--
-- ARM 7.3.2(26-35) Type Invariants
--
-- Success: 27:1..54:16 Tree *
--
-- package Work_Orders is
--    type Work_Order is private with
--      Type_Invariant => (Day_Scheduled (Work_Order) in Weekday
--                        or else (Priority (Work_Order) = Urgent));
--    function Schedule_Work (Urgency  : Level;
--                            To_Occur : Day) return Work_Order
--      with Pre => ((Urgency = Urgent) or else To_Occur in Weekday);
--    function Day_Scheduled (Order : Work_Order) return Day;
--    function Priority (Order : Work_Order) return Level;
--    procedure Change_Priority (Order        : in out Work_Order;
--                               New_Priority :      Level;
--                               Changed      : out    Boolean)
--       with Post => (Changed = (Day_Scheduled (Order) in Weekday
--                               or else (Priority (Order) = Urgent)));
-- private
--    type Work_Order is record
--       Scheduled : Day;
--       Urgency   : Level;
--    end record;
-- end Work_Orders;
--
package Work_Orders is
   -- See 3.5.1 for type declarations of Level, Day, and Weekday

   type Work_Order is private with
     Type_Invariant => Day_Scheduled (Work_Order) in Weekday
                       or else Priority (Work_Order) = Urgent;

   function Schedule_Work (Urgency  : in Level;
                           To_Occur : in Day) return Work_Order
     with Pre => Urgency = Urgent or else To_Occur in Weekday;

   function Day_Scheduled (Order : in Work_Order) return Day;

   function Priority (Order : in Work_Order) return Level;

   procedure Change_Priority (Order        : in out Work_Order;
                              New_Priority : in     Level;
                              Changed      : out    Boolean)
      with Post => Changed = (Day_Scheduled(Order) in Weekday
                              or else Priority(Order) = Urgent);
private

   type Work_Order is record
      Scheduled : Day;
      Urgency   : Level;
   end record;

end Work_Orders;