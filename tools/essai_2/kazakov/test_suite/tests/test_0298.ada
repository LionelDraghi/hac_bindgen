--
-- ACATS B56001F
--
-- Failure: 'null' is unexpected inside a declarative part as found at 9:14..17
--
PROCEDURE B56001F IS
BEGIN

     DECLARE NULL;                      -- ERROR: STMT BEFORE BEGIN.
     BEGIN NULL; END;

END B56001F;
