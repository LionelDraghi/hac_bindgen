--
-- ARM 3.9_1(4 p/5) Type Extensions
--
-- Success: 15:1..22:30 Tree *
--
-- package ARM_3_9_1.Type_Extensions is
--    type T1 is tagged null record;
--    type T2 is new T1 with record
--       Comp : Some_Controlled_Type;
--    end record;
--    function Func return T1'Class is (T2'(others => <>));
--    X : T1'Class := Func;
-- end ARM_3_9_1.Type_Extensions;
--
package ARM_3_9_1.Type_Extensions is
   type T1 is tagged null record;
   type T2 is new T1 with record
      Comp : Some_Controlled_Type;
   end record;
   function Func return T1'Class is (T2'(others => <>));
   X : T1'Class := Func;
end ARM_3_9_1.Type_Extensions;