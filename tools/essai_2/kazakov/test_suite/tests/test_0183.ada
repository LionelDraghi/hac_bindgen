--
-- ACATS B28001S.ADA
--
-- Failure: 'when' is expected at 12:1..10
--
PROCEDURE B28001S IS

     CHOICE : BOOLEAN := TRUE;

BEGIN
     CASE CHOICE IS
          PRAGMA ROSA_WILLIAMS;
     END CASE;                       -- ERROR: MISSING ALTERNATIVE.
END B28001S;
