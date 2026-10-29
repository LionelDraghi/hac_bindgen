--
-- ACATS B53001B
--
-- Failure: 'end if' is expected at 19:6..9
--
PROCEDURE B53001B IS

     B1, B2 : BOOLEAN;
     I1, I2 : INTEGER;

BEGIN
     B1 := TRUE;
     B2 := FALSE;

     IF B1 THEN
          IF B2 THEN
               B1 := FALSE;
          ELSE B2 := TRUE;
     ELSE I2 := 0;             -- ERROR: "END IF;" MISSING.
     END IF;

END B53001B;