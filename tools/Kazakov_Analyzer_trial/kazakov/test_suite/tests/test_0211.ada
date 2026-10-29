--
-- ACATS B37004F
--
-- Failure: 'when' is expected after 'is' at 18:20..20
--
PROCEDURE B37004F IS

     SUBTYPE S1 IS INTEGER RANGE 1 .. 1;

     TYPE R1 (D : S1) IS RECORD
          CASE D IS
               WHEN 1 => NULL;
          END CASE;
     END RECORD;                        -- OK.

     SUBTYPE NULL_BOOL IS BOOLEAN RANGE TRUE .. FALSE;
     TYPE REC (D : NULL_BOOL) IS RECORD
          CASE D IS END CASE;           -- ERROR: MISSING CHOICE.
     END RECORD;

BEGIN
     NULL;

END B37004F;