--
-- ACATS B54A01G
--
-- Failure: Semicolon is expected at 14:14..14
--
PROCEDURE B54A01G IS

     I : INTEGER := 4;

BEGIN

     <<LABEL>> CASE I IS
          WHEN OTHERS => NULL;
     END CASE LABEL;              -- ERROR: LABEL.

END B54A01G;
