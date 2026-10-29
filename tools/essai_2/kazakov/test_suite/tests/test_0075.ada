--
-- ARM 6.7 Null Procedures
--
-- Success: 12:1..16:12 Tree *
--
-- package body ARM_6_7 is
--    procedure Simplify (Expr : in out Expression) is null;
-- begin
--    null;
-- end ARM_6_7;
--
package body ARM_6_7 is
   procedure Simplify(Expr : in out Expression) is null; -- see 3.9
begin
   null;
end ARM_6_7;