package Geometry is

   type Point is record
      X, Y : Integer;
   end record;

   procedure Translate (P : in out Point; Dx, Dy : in Integer);

   function Distance (A, B : Point) return Long_Float;

   function Midpoint (A, B : Point) return Point;

end Geometry;
