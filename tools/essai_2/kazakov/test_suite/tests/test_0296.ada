--
-- ACATS B56001D
--
-- Failure: 'exception' is unexpected inside a declarative part as found at 9:14..22
--
PROCEDURE B56001D IS
BEGIN

     DECLARE EXCEPTION                       -- ERROR: MISSING BEGIN.
          WHEN OTHERS => NULL;
     END;

END B56001D;
