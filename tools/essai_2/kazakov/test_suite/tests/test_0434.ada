--
-- ACATS B85001K
--
-- Failure: Index constraint is not allowed in renaming at 12:10..27
--
PROCEDURE B85001K IS

     TYPE ARR IS ARRAY (INTEGER RANGE <>) OF INTEGER;

     A0 : ARR(1..10);

     A : ARR(1..10) RENAMES A0;              -- ERROR: INDEX CONSTRAINT.

BEGIN
     NULL;
END B85001K;
