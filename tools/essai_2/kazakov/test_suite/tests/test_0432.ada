--
-- ACATS B85001I
--
-- Failure: Range constraint is not allowed in renaming at 10:10..35
--
PROCEDURE B85001I IS

     I0 : INTEGER RANGE 0..9;

     I : INTEGER RANGE 0..9 RENAMES I0;      -- ERROR: RANGE CONSTRAINT.

BEGIN
     NULL;
END B85001I;
