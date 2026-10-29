--
-- ACATS B61001F
--
-- Failure: Either ';' or closing ')' matching '(' at 8:19..19 is expected after a parameter at 8:33
--
PROCEDURE B61001F IS

     PROCEDURE P2 (X: IN INTEGER, Y: OUT INTEGER) IS  -- ERROR: ,
     BEGIN
          NULL;
     END P2;

BEGIN

     NULL;

END B61001F;
