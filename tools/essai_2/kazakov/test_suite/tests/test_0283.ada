--
-- ACATS B55A01D
--
-- Failure: 'loop' is expected at 12:22
--
PROCEDURE B55A01D IS

     I : INTEGER;

BEGIN

     FOR I IN 1 .. 10;                -- ERROR: ';'.
          NULL;
     END LOOP;

END B55A01D;
