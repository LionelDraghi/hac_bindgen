--
-- ACATS B91002G
--
-- Failure: 'procedure' is unexpected inside a task public items context as found at 12:11..19
--
PROCEDURE B91002G IS

     TASK TYPE T2G IS

          ENTRY E;

          PROCEDURE P;               -- ERROR: PROHIBITED IN TASK SPEC.

     END T2G;

     TASK BODY T2G IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002G;
