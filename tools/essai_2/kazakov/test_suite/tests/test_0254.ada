--
-- ACATS B52002D
--
-- Failure: A variable name is expected at 12:6..7
--
PROCEDURE B52002D IS

     I1 : INTEGER := 1 ;

BEGIN

     99 := I1;          -- ERROR: LITERAL ON LEFT.

END B52002D;
