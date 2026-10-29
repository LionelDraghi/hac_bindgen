--
-- ACATS B55A01E
--
-- Failure: 'loop' is expected at 12:15
--
PROCEDURE B55A01E IS

     VBF : BOOLEAN := FALSE;

BEGIN

     WHILE VBF;                          -- ERROR: ';'.
          NULL;
     END LOOP;

END B55A01E;