--
-- ACATS B52002E
--
-- Failure: Left part of assignment cannot be an expression as found at 14:6..11
--
PROCEDURE B52002E IS


     EX : INTEGER := 1 ;
     I1 : INTEGER := 1 ;

BEGIN

     (2*I1) := 45;      -- ERROR: EXPRESSION ON LEFT.


END B52002E;
