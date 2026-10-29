--
-- ARM 4.3.4 Delta Aggregates
--
-- Success: 23:1..45:14 Tree *
--
-- package body ARM_4_3_4 is
--    procedure Twelfth (D : in out Date)
--       with Post => (D = (D'Old, with delta Day => 12));
--    procedure The_Answer (V : in out Vector;
--                          A, B : Integer)
--       with Post => (V = (V'Old, with delta A..B => 42.0, V'First => 0.0));
--    New_Cell : Cell := (Min_Cell (Head), with delta Value => 42);
--    A1 : Vector := ((0 => 1.0, 1 => 2.0, 2 => 3.0),
--           with delta Integer ((Random * 2.0)) => 14.2);
--    function Translate (P : Point'Class; X, Y : Real) return Point'Class is
--       ((P, with delta X => (P.X + X),
--                     Y => (P.Y + Y)));
-- begin
--    Tomorrow := ((Yesterday, with delta Day => 12),
--                      with delta Month => April);
-- end ARM_4_3_4;
--
package body ARM_4_3_4 is
   procedure Twelfth (D : in out Date) -- see 3.8 for type Date
      with Post => D = (D'Old with delta Day => 12);

   procedure The_Answer (V : in out Vector;
                         A, B : in Integer) -- see 3.6 for type Vector
      with Post => V = (V'Old with delta A .. B => 42.0, V'First => 0.0);

   New_Cell : Cell := (Min_Cell (Head) with delta Value => 42);
      -- see 3.10.1 for Cell and Head; 6.1 for Min_Cell

   A1 : Vector := ((0 => 1.0, 1 => 2.0, 2 => 3.0)
          with delta Integer(Random * 2.0) => 14.2);
      -- see 3.6 for declaration of type Vector
      -- see 6.1 for declaration of Random

   function Translate (P : Point'Class; X, Y : Real) return Point'Class is
      (P with delta X => P.X + X,
                    Y => P.Y + Y); -- see 3.9 for declaration of type Pointend ARM_4_2_1;
begin
   Tomorrow := ((Yesterday with delta Day => 12)
                     with delta Month => April); -- see 3.8
end ARM_4_3_4;