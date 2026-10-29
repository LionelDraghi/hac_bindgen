--
-- ACATS B53009A
--
-- Failure: 'declare', 'begin', 'loop', 'parallel' or 'while' is expected at 17:16
--
PROCEDURE B53009A IS

     I1, I2, I3 : INTEGER;
     B1, B2 : BOOLEAN;
     L1 : CHARACTER;

BEGIN
     B1 := TRUE; B2 := FALSE;
     I1 := 5; I2 := 9; I3 := 0;

     IF B1 THEN
          I4 : INTEGER;    -- ERROR: ALTERNATIVE BEGINS WITH DECLARATION
          I3 := 9;
     END IF;

END B53009A;