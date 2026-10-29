--
-- ACATS B55A01T
--
-- Failure: Expression is expected at 12:10
--
PROCEDURE B55A01T IS

     VBT : BOOLEAN := TRUE;

BEGIN

     LOOP;               -- ERROR: ';'.
          EXIT WHEN VBT;
     END LOOP;

END B55A01T;