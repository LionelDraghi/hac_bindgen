--
-- ACATS B85001J
--
-- Failure: Fixed-point constraint is not allowed in renaming at 12:10..34
--
PROCEDURE B85001J IS

     TYPE FIX IS DELTA 2#0.01# RANGE -100.0 .. 100.0;

     X0 : FIX;

     X : FIX DELTA 2#0.01# RENAMES X0;  -- ERROR: ACCURACY CONSTRAINT.

BEGIN
     NULL;
END B85001J;
