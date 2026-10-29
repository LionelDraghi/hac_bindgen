--
-- ARM 10.1.1(30-34) Compilation Units - Library Units
--
-- Success: 27:1..30:24, 32:9..63, 36:1..38:21, 42:1..49:9, 52:1..48 Tree *
--
-- package Rational_Numbers.IO is
--    procedure Put (R : Rational);
--    procedure Get (R : out Rational);
-- end Rational_Numbers.IO;
-- private procedure Rational_Numbers.Reduce (R : in out Rational);
-- with Rational_Numbers.Reduce;
-- package body Rational_Numbers is
-- end Rational_Numbers;
-- with Rational_Numbers.IO; use Rational_Numbers;
-- with Ada.Text_io;
-- procedure Main is
--    R : Rational;
-- begin
--    R := (5 / 3);
--    Ada.Text_IO.Put ("The answer is: ");
--    IO.Put (R);
--    Ada.Text_IO.New_Line;
-- end Main;
-- with Rational_Numbers.IO;
-- package Rational_IO renames Rational_Numbers.IO;
--
package Rational_Numbers.IO is  -- public child of Rational_Numbers, see 7.1
   procedure Put(R : in  Rational);
   procedure Get(R : out Rational);
end Rational_Numbers.IO;

private procedure Rational_Numbers.Reduce(R : in out Rational);
                                -- private child of Rational_Numbers

with Rational_Numbers.Reduce;   -- refer to a private child
package body Rational_Numbers is
   -- ...
end Rational_Numbers;

with Rational_Numbers.IO; use Rational_Numbers;
with Ada.Text_io;               -- see A.10
procedure Main is               -- a root library procedure
   R : Rational;
begin
   R := 5/3;                    -- construct a rational number, see 7.1
   Ada.Text_IO.Put("The answer is: ");
   IO.Put(R);
   Ada.Text_IO.New_Line;
end Main;

with Rational_Numbers.IO;
package Rational_IO renames Rational_Numbers.IO;