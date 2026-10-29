--
-- ACATS B91002K
--
-- Failure: 'task' is unexpected inside a task public items context as found at 12:11..14
--
PROCEDURE B91002K IS

     TASK TYPE T2K IS

          ENTRY E;

          TASK T2;                   -- ERROR: PROHIBITED IN TASK SPEC.

     END T2K;

     TASK BODY T2K IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002K;
