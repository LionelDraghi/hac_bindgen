--
-- ACATS B54A01B
--
-- Failure: 'is' is expected at 12:13
--
PROCEDURE B54A01B IS

     I : INTEGER := 4;

BEGIN

     CASE I WHEN OTHERS => NULL;   -- ERROR: MISSING 'IS'.
     END CASE;

END B54A01B;
