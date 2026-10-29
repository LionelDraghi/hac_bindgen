--
-- ACATS B36171F
--
-- Failure: Closing parenthesis ')' matching the opening one '(' at 9:11..11 is expected at 9:20
--
PROCEDURE B36171F IS

     TYPE T IS NEW STRING
          (NATURAL RANGE <>);            -- ERROR: <>.

BEGIN
     NULL;

END B36171F;
