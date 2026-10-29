--
-- ARM 7.2 Package Bodies
--
-- Success: 32:1..62:21 Tree *
--
-- package body Rational_Numbers is
--    procedure Same_Denominator (X, Y : in out Rational) is
--    begin
--       null;
--    end Same_Denominator;
--    function "=" (X, Y : Rational) return Boolean is
--       U : Rational := X;
--       V : Rational := Y;
--    begin
--       Same_Denominator (U, V);
--       return (U.Numerator = V.Numerator);
--    end "=";
--    function "/" (X, Y : Integer) return Rational is
--    begin
--       if (Y > 0) then
--          return (Numerator => X,  Denominator => Y);
--       else
--          return (Numerator => -(X), Denominator => -(Y));
--       end if;
--    end "/";
--    function "+" (X, Y : Rational) return Rational is begin null; end "+";
--    function "-" (X, Y : Rational) return Rational is begin null; end "-";
--    function "*" (X, Y : Rational) return Rational is begin null; end "*";
--    function "/" (X, Y : Rational) return Rational is begin null; end "/";
-- end Rational_Numbers;
--
package body Rational_Numbers is

   procedure Same_Denominator (X,Y : in out Rational) is
   begin
      --  reduces X and Y to the same denominator:
      null;
   end Same_Denominator;

   function "="(X,Y : Rational) return Boolean is
      U : Rational := X;
      V : Rational := Y;
   begin
      Same_Denominator (U,V);
      return U.Numerator = V.Numerator;
   end "=";

   function "/" (X,Y : Integer) return Rational is
   begin
      if Y > 0 then
         return (Numerator => X,  Denominator => Y);
      else
         return (Numerator => -X, Denominator => -Y);
      end if;
   end "/";

   function "+" (X,Y : Rational) return Rational is begin null; end "+";
   function "-" (X,Y : Rational) return Rational is begin null; end "-";
   function "*" (X,Y : Rational) return Rational is begin null; end "*";
   function "/" (X,Y : Rational) return Rational is begin null; end "/";

end Rational_Numbers;