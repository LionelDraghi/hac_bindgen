--
-- ARM 4.5.2(30) Relational Operators and Membership Tests
--
-- Success: 18:1..28:14 Tree *
--
-- package ARM_4_5_2 is
--     type Root is tagged null record;
--     type Ext is new Root with record Data : Integer; end record;
--     function Is_Even (Param : Ext) return Boolean is
--        (((Param.Data mod 2) = 0));
--     subtype Even_Ext is Ext
--       with Dynamic_Predicate => Is_Even (Even_Ext);
--     function F (X : Root'Class) return Boolean is
--        (X in Even_Ext);
--     Flag : Boolean := F (Root'(null record));
-- end ARM_4_5_2;
--
package ARM_4_5_2 is
   type Root is tagged null record;
   type Ext is new Root with record Data : Integer; end record;
   function Is_Even (Param : Ext) return Boolean is
      (Param.Data mod 2 = 0);
   subtype Even_Ext is Ext
     with Dynamic_Predicate => Is_Even (Even_Ext);
   function F (X : Root'Class) return Boolean is
      ((X in Even_Ext));
   Flag : Boolean := F (Root'(null record));
end ARM_4_5_2;