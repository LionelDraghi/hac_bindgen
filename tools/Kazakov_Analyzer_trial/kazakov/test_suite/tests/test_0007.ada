--
-- ARM 3.2.2 Subtype Declarations
--
-- Success: 19:1..30:35 Tree *
--
-- procedure ARM_3_2_2.Subtype_Declarations is
--    subtype Rainbow is Color range Red..Blue;
--    subtype Red_Blue is Rainbow;
--    subtype Int is Integer;
--    subtype Small_Int is Integer range -(10)..10;
--    subtype Up_To_K is Column range 1..K;
--    subtype Square is Matrix (1..10, 1..10);
--    subtype Male is Person (Sex => M);
--    subtype Binop_Ref is not null Binop_Ptr;
-- begin
--    null;
-- end ARM_3_2_2.Subtype_Declarations;
--
procedure ARM_3_2_2.Subtype_Declarations is
   subtype Rainbow   is Color range Red .. Blue;      -- see 3.2.1
   subtype Red_Blue  is Rainbow;
   subtype Int       is Integer;
   subtype Small_Int is Integer range -10 .. 10;
   subtype Up_To_K   is Column range 1 .. K;          -- see 3.2.1
   subtype Square    is Matrix(1 .. 10, 1 .. 10);     -- see 3.6
   subtype Male      is Person(Sex => M);             -- see 3.10.1
   subtype Binop_Ref is not null Binop_Ptr;           -- see 3.10
begin
   null;
end ARM_3_2_2.Subtype_Declarations;
