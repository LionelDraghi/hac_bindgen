--
-- ACATS B35901A
--
-- Failure: Range of the ordinary fixed-point type is axpected at 8:34
--
PROCEDURE B35901A IS

     TYPE FIXED_TYPE IS DELTA 0.1;      -- ERROR: NO RANGE SPECIFIED.

BEGIN
     NULL;
END B35901A;