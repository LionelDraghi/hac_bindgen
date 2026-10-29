--
-- ARM 3.6 Array Types
--
-- Success: 23:1..41:24 Tree *
--
-- package ARM_3_6.Array_Types is
--    type Vector     is array (Integer  range <>) of Real;
--    type Matrix     is array (Integer  range <>, Integer range <>) of Real;
--    type Bit_Vector is array (Integer  range <>) of Boolean;
--    type Roman      is array (Positive range <>) of Roman_Digit;
--    type Table    is array (1..10) of Integer;
--    type Schedule is array (Day) of Boolean;
--    type Line     is array (1..Max_Line_Size) of Character;
--    Grid      : array (1..80, 1..100) of Boolean;
--    Mix       : array (Color range Red..Green) of Boolean;
--    Msg_Table : constant array (Error_Code) of access constant String :=
--          (Too_Big => new (String'("Result too big")), Too_Small => new (String'("Result too small")));
--    Page      : array (Positive range <>) of Line :=
--      (1 | 50  => Line'(1 | Line'Last => '+', others => '-'),
--       2..49 => Line'(1 | Line'Last => '|', others => ' '));
-- end ARM_3_6.Array_Types;
--
package ARM_3_6.Array_Types is
   type Vector     is array(Integer  range <>) of Real;
   type Matrix     is array(Integer  range <>, Integer range <>) of Real;
   type Bit_Vector is array(Integer  range <>) of Boolean;
   type Roman      is array(Positive range <>) of Roman_Digit; -- see 3.5.2

   type Table    is array(1 .. 10) of Integer;
   type Schedule is array(Day) of Boolean;
   type Line     is array(1 .. Max_Line_Size) of Character;

   Grid      : array(1 .. 80, 1 .. 100) of Boolean;
   Mix       : array(Color range Red .. Green) of Boolean;
   Msg_Table : constant array(Error_Code) of access constant String :=
         (Too_Big => new String'("Result too big"), Too_Small => new String'("Result too small"));
   Page      : array(Positive range <>) of Line := -- an array of arrays
     (1 | 50  => Line'(1 | Line'Last => '+', others => '-'), -- see 4.3.3
      2 .. 49 => Line'(1 | Line'Last => '|', others => ' '));
    -- Page is constrained by its initial value to (1..50)
end ARM_3_6.Array_Types;