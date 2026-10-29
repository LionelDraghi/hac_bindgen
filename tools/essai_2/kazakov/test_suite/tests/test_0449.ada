--
-- ACATS B91002E
--
-- Failure: 'type' is unexpected inside a task public items context as found at 12:11..14
--
PROCEDURE B91002E IS

     TASK TYPE T2E IS

          ENTRY E;

          TYPE B IS ARRAY (1..4) OF BOOLEAN; -- ERROR: PROHIBITED IN
                                             --        TASK SPEC.

     END T2E;

     TASK BODY T2E IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002E;