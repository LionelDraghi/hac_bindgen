--
-- ACATS B91002J
--
-- Failure: 'task' is unexpected inside a task public items context as found at 12:11..14
--
PROCEDURE B91002J IS

     TASK TYPE T2J IS

          ENTRY E;

          TASK TYPE T1;              -- ERROR: PROHIBITED IN TASK SPEC.

     END T2J;

     TASK BODY T2J IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002J;