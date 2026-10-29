--
-- ACATS B28001V.ADA
--
-- Failure: 'when' is expected after 'exception' at 14:1..10
--
PROCEDURE B28001W IS

     A : INTEGER := 1;

BEGIN
     BEGIN
          A := A + 1;
     EXCEPTION
          PRAGMA ROSA_WILLIAMS;
     END;                                     -- ERROR: MISSING HANDLER.
END B28001W;
