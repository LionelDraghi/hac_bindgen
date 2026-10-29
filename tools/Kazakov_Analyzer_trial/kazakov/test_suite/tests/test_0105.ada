--
-- ARM 9.4(27-35) Protected Units and Protected Objects
--
-- Success: 43:1..85:12 Tree *
--
-- package body ARM_9_4 is
--    protected type Resource is
--       entry Seize;
--       procedure Release;
--    private
--       Busy : Boolean := False;
--    end Resource;
--    protected body Resource is
--       entry Seize when not (Busy) is
--       begin
--          Busy := True;
--       end Seize;
--       procedure Release is
--       begin
--          Busy := False;
--       end Release;
--    end Resource;
--    protected Shared_Array is
--       function  Component    (N : Index) return Item;
--       procedure Set_Component (N : Index; E : Item);
--    private
--       Table : Item_Array (Index) := (others => Null_Item);
--    end Shared_Array;
--    protected body Shared_Array is
--       function Component (N : Index) return Item is
--       begin
--          return Table (N);
--       end Component;
--       procedure Set_Component (N : Index; E : Item) is
--       begin
--          Table (N) := E;
--       end Set_Component;
--    end Shared_Array;
--    Control  : Resource;
--    Flags    : array (1..100) of Resource;
-- end ARM_9_4;
--
package body ARM_9_4 is
   protected type Resource is
      entry Seize;
      procedure Release;
   private
      Busy : Boolean := False;
   end Resource;

   protected body Resource is
      entry Seize when not Busy is
      begin
         Busy := True;
      end Seize;

      procedure Release is
      begin
         Busy := False;
      end Release;
   end Resource;

   protected Shared_Array is
      --  Index, Item, and Item_Array are global types
      function  Component    (N : in Index) return Item;
      procedure Set_Component(N : in Index; E : in  Item);
   private
      Table : Item_Array(Index) := (others => Null_Item);
   end Shared_Array;

   protected body Shared_Array is
      function Component(N : in Index) return Item is
      begin
         return Table(N);
      end Component;

      procedure Set_Component(N : in Index; E : in Item) is
      begin
         Table(N) := E;
      end Set_Component;
   end Shared_Array;

   Control  : Resource;
   Flags    : array(1 .. 100) of Resource;
end ARM_9_4;