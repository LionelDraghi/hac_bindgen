--
-- Access types
--
-- Success: 18:1..29:16
--
-- procedure Access_Type is
--    type A1 is access Integer range 1..2;
--    type A2 is access Float digits 1;
--    type A3 is access AS (1..4);
--    type A4 is access all Integer range 1..2;
--    type A5 is access constant Float digits 1 range 0.0..90.0;
--    type A6 is not null access all Float digits 1;
--    type A7 is not null access constant not null Ptr;
-- begin
--      null;
-- end Access_Type;
--
procedure Access_Type is

   type A1 is access Integer range 1 .. 2;
   type A2 is access Float digits 1;
   type A3 is access AS (1 .. 4);
   type A4 is access all Integer range 1 .. 2;
   type A5 is access constant Float digits 1 range 0.0..90.0;
   type A6 is not null access all Float digits 1;
   type A7 is not null access constant not null Ptr;
begin
     NULL;
end Access_Type;