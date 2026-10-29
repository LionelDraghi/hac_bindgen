--
-- ACATS B95030A
--
-- Failure: 'entry' is unexpected inside a declarative part as found at 13:11..15
--
PROCEDURE B95030A IS

     TASK T1 IS
          ENTRY E1;      -- OK.
     END T1;

     TASK BODY T1 IS
          ENTRY E2;      -- ERROR: ENTRY DECLARED IN BODY.
     BEGIN
          ACCEPT E1;     -- OK.
     END T1;

BEGIN
     NULL;
END B95030A;
