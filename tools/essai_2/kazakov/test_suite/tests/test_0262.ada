--
-- ACATS B54A01F
--
-- Failure: Semicolon is expected at 14:14..14
--
PROCEDURE B54A01F IS

     I : INTEGER := 4;

BEGIN

     CASE I IS
          WHEN OTHERS => NULL;
     END CASE I;                  -- ERROR: I.

END B54A01F;

