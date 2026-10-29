--
-- ARM 6.8 Expression Functions
--
-- Success: 11:1..14:12 Tree *
--
-- package ARM_6_8 is
--    function Is_Origin (P : Point) return Boolean is
--       (((P.X = 0.0) and (P.Y = 0.0)));
-- end ARM_6_8;
--
package ARM_6_8 is
   function Is_Origin (P : in Point) return Boolean is -- see 3.9
      (P.X = 0.0 and P.Y = 0.0);
end ARM_6_8;