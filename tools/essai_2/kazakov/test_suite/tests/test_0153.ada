--
-- Types https://en.wikibooks.org/wiki/Ada_Programming/Type_System
--
-- Success: 21:1..38:18 find Integer_1 at 26:29..37 = 24:7..28:3(1)  find Integer_1 at 24:1..1 = empty
--                      find A         at 32:7..7   = 23:4..34:0(3)  find B         at 36:7..7 = 23:4..34:0(4)
--                      find Pak       at 36:0      = 23:4..34:0(1)  find B         at 32:20   = empty
--
--  procedure Derived_Types is
--     package Pak is
--        type Integer_1 is range 1..10;
--        procedure P (I : Integer_1);
--        type Integer_2 is new Integer_1 range 8..10;
--     end Pak;
--     use Pak;
--     A : Integer_1 := 4;
--     B : Integer_2 := 9;
--  begin
--     P (B);
--  end Derived_Types;
--
procedure Derived_Types is

   package Pak is
      type Integer_1 is range 1 .. 10;
      procedure P (I: in Integer_1); -- primitive operation, assumes 1 .. 10
      type Integer_2 is new Integer_1 range 8 .. 10; -- must not break P's assumption
      -- procedure P (I: in Integer_2);  inherited P implicitly find here
   end Pak;

   use Pak;
   A: Integer_1 := 4;
   B: Integer_2 := 9;

begin

   P (B); -- OK, call the inherited operation

end Derived_Types;