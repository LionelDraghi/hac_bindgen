--
-- ACATS B36171D
--
-- Failure: Expression is expected at 8:23
--
PROCEDURE B36171D IS

     TYPE T IS ARRAY () OF BOOLEAN;          -- ERROR: ().

BEGIN
     NULL;

END B36171D;
