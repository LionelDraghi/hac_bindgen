--
-- ACATS B55A01L
--
-- Failure: 'loop' is expected after 'end' at 14:9
--
PROCEDURE B55A01L IS

     VBF : BOOLEAN := FALSE;

BEGIN

     WHILE VBF LOOP
          NULL;
     END;                -- ERROR: END LOOP REQUIRED.

END B55A01L;
