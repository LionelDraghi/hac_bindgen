with Ada.Numerics.Long_Elementary_Functions;

package body Geometry is

   procedure Translate (P : in out Point; Dx, Dy : in Integer) is
   begin
      P.X := P.X + Dx;
      P.Y := P.Y + Dy;
   end Translate;

   function Distance (A, B : Point) return Long_Float is
      use Ada.Numerics.Long_Elementary_Functions;
      DX : constant Long_Float := Long_Float (B.X - A.X);
      DY : constant Long_Float := Long_Float (B.Y - A.Y);
   begin
      return Sqrt (DX * DX + DY * DY);
   end Distance;

   function Midpoint (A, B : Point) return Point is
   begin
      return (X => (A.X + B.X) / 2,
              Y => (A.Y + B.Y) / 2);
   end Midpoint;

end Geometry;
