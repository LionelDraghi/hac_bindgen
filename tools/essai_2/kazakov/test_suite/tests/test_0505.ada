--
-- Description: Nested generic procedure declaration
--
-- Success: 14:1..20:6 Tree *
--
-- procedure P is
--    generic
--       F : in out Integer;
--    procedure Q;
-- begin
--    null;
-- end P;
--
procedure P is
   generic
      F : in out Integer;
   procedure Q;
begin
   null;
end P;
