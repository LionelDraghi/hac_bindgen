--
-- ACATS B28001T.ADA
--
-- Failure: 'pragma' is unexpected after 'select' at 15:16..21
--
PROCEDURE B28001T IS

     TASK T1 IS
          ENTRY E1;
     END T1;

     TASK BODY T1 IS
     BEGIN
          SELECT
               PRAGMA LIST (ON);
          END SELECT;                     -- ERROR: MISSING ALTERNATIVE.
     END T1;

BEGIN
     NULL;
END B28001T;
