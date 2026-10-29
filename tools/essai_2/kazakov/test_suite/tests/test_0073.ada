--
-- ARM 6.3(11) Subprogram Bodies
--
-- Success: 16:1..24:16 Tree *
--
-- function Dot_Product (Left, Right : Vector) return Real is
--    Sum : Real := 0.0;
-- begin
--    Check (((Left'First = Right'First) and (Left'Last = Right'Last)));
--    for J in Left'Range loop
--       Sum := (Sum + (Left (J) * Right (J)));
--    end loop;
--    return Sum;
-- end Dot_Product;
--
function Dot_Product(Left, Right : Vector) return Real is
   Sum : Real := 0.0;
begin
   Check(Left'First = Right'First and Left'Last = Right'Last);
   for J in Left'Range loop
      Sum := Sum + Left(J)*Right(J);
   end loop;
   return Sum;
end Dot_Product;