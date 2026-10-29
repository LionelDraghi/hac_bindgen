--
-- ACATS B36171C
--
-- Failure: Operand is expected at 11:24
--
PROCEDURE B36171C IS

     TYPE D1 IS ARRAY (INTEGER RANGE <>)
          OF BOOLEAN RANGE TRUE .. FALSE;

     TYPE T IS NEW D1 ();                    -- ERROR: ().

BEGIN
     NULL;

END B36171C;