--
-- ARM 3.9_4(1 c/2) Interface Types
--
-- Success: 11:1..16:6 Tree *
--
-- procedure X is
--    type Con1 is new Int1 and Int2 with null record;
--    type Con2 is new Int2 and Int1 with null record; begin null;
-- end X;
--
procedure X is
   type Con1 is new Int1 and Int2 with null record;
   type Con2 is new Int2 and Int1 with null record;
begin
   null;
end X;