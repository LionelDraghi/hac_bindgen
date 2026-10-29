--
-- ACATS B55A01K
--
-- Failure: 'loop' is expected after 'end' at 14:9
--
PROCEDURE B55A01K IS

     I : INTEGER;

BEGIN

     FOR I IN 1 .. 10 LOOP
          NULL;
     END;                     -- ERROR: END LOOP REQUIRED.

END B55A01K;
