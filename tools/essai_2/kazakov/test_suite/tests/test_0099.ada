--
-- ARM 8.5.4(14-21) Subprogram Renaming Declarations
--
-- Success: 18:1..34:14 Tree *
--
-- package ARM_8_5_4 is
--    procedure My_Write (C : Character) renames Pool (K).Write;
--    function Real_Plus (Left, Right : Real) return Real    renames "+";
--    function Int_Plus (Left, Right : Integer) return Integer renames "+";
--    function Rouge return Color renames Red;
--    function Rot   return Color renames Red;
--    function Rosso return Color renames Rouge;
--    function Next (X : Color) return Color renames Color'Succ;
--    function "*" (X, Y : Vector) return Real renames Dot_Product;
--    function Minimum (L : Link := Head) return Cell renames Min_Cell;
-- end ARM_8_5_4;
--
package ARM_8_5_4 is

   procedure My_Write(C : in Character) renames Pool(K).Write; --  see 4.1.3

   function Real_Plus(Left, Right : Real   ) return Real    renames "+";
   function Int_Plus (Left, Right : Integer) return Integer renames "+";

   function Rouge return Color renames Red;  --  see 3.5.1
   function Rot   return Color renames Red;
   function Rosso return Color renames Rouge;

   function Next(X : Color) return Color renames Color'Succ; -- see 3.5.1

   function "*" (X,Y : Vector) return Real renames Dot_Product; -- see 6.1

   function Minimum(L : Link := Head) return Cell renames Min_Cell; -- see 6.1
end ARM_8_5_4;