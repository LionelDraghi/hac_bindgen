--
-- ACATS B55A01U
--
-- Failure: Expression is expected at 12:25
--
PROCEDURE B55A01U IS

     I : INTEGER;

BEGIN

     FOR I IN 1..10 LOOP;     -- ERROR: ';'.
          NULL;
     END LOOP;

END B55A01U;
