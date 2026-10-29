--
-- ACATS B28001U.ADA
--
-- Failure: 'accept', 'delay', or 'terminate' is expected at 16:21..26
--
PROCEDURE B28001U IS

     TASK T1 IS
          ENTRY E1;
     END T1;

     TASK BODY T1 IS
     BEGIN
          SELECT
               WHEN TRUE =>
                    PRAGMA THOMAS_NORRIS;
          END SELECT;                               -- ERROR: NO ACCEPT,
                                                    --        DELAY, OR
                                                    --        TERMINATE.
     END T1;

BEGIN
     NULL;
END B28001U;