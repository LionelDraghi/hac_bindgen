--
-- ACATS B37004D
--
-- Failure: No record member declarations found before 'end' at 11:6
--
PROCEDURE B37004D IS

     SUBTYPE S1 IS INTEGER RANGE 1 .. 1;

     TYPE REC (D : S1) IS RECORD
     END RECORD;                        -- ERROR: MISSING NULL.

BEGIN
     NULL;

END B37004D;