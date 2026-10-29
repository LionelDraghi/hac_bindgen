--
-- ACATS B37004E
--
-- Failure: No record member declarations found before 'end' at 17:31
--
PROCEDURE B37004E IS

     SUBTYPE S1 IS INTEGER RANGE 1 .. 1;

     TYPE R1 (D : S1) IS RECORD
          CASE D IS
               WHEN 1 => NULL;
          END CASE;
     END RECORD;                              -- OK.

     TYPE R2 (D : S1) IS RECORD
          CASE D IS WHEN 1 => END CASE;       -- ERROR: MISSING NULL.
     END RECORD;

BEGIN
     NULL;

END B37004E;