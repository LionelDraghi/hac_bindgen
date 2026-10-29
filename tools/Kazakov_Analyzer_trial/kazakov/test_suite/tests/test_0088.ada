--
-- ARM 8.3(12) Visibility
--
-- Success: 20:1..34:10 Tree *
--
-- package Outer is
--    package P1 is
--       type Ifc1 is interface;
--       procedure Null_Procedure (X : Ifc1) is null;
--       procedure Abstract_Subp  (X : Ifc1) is abstract;
--    end P1;
--    package P2 is
--       type Ifc2 is interface;
--       procedure Null_Procedure (X : Ifc2) is null;
--       procedure Abstract_Subp  (X : Ifc2) is abstract;
--    end P2;
--    type T is abstract new P1.Ifc1 and P2.Ifc2 with null record;
-- end Outer;
--
package Outer is
   package P1 is
      type Ifc1 is interface;
      procedure Null_Procedure (X : Ifc1) is null;
      procedure Abstract_Subp  (X : Ifc1) is abstract;
   end P1;

   package P2 is
      type Ifc2 is interface;
      procedure Null_Procedure (X : Ifc2) is null;
      procedure Abstract_Subp  (X : Ifc2) is abstract;
   end P2;

   type T is abstract new P1.Ifc1 and P2.Ifc2 with null record;
end Outer;