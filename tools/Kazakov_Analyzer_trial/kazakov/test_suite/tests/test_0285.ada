--
-- ACATS B55A01J
--
-- Failure: 'loop' is expected after 'end' at 15:9..9
--
PROCEDURE B55A01J IS

     VBF : BOOLEAN := FALSE;

BEGIN

L20:
     WHILE VBF LOOP
          NULL;
     END L20;       -- ERROR: "END LOOP L20" REQUIRED.

END B55A01J;
