--
-- ACATS B55A01V
--
-- Failure: Expression is expected at 12:20
--
PROCEDURE B55A01V IS

     VBF : BOOLEAN := FALSE;

BEGIN

     WHILE VBF LOOP;     -- ERROR: ';'.
          NULL;
     END LOOP;

END B55A01V;
