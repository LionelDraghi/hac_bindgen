--
-- ACATS B55A01O
--
-- Failure: 'loop' is expected at 14:16
--
PROCEDURE B55A01O IS

     VBF : BOOLEAN := FALSE;

     I : INTEGER;

BEGIN

     WHILE VBF FOR I IN 1 .. 10 LOOP    -- ERROR: ILLEGAL SYNTAX
          NULL;                         -- (WHILE ... FOR ...).
     END LOOP;

END B55A01O;
