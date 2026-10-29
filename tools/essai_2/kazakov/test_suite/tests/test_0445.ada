--
-- ACATS B91002A
--
-- Failure: A task item declaration is expected at 12:11
--
PROCEDURE B91002A IS

     TASK TYPE T2A IS

          ENTRY E;

          I : INTEGER;               -- ERROR: PROHIBITED IN TASK SPEC.

     END T2A;

     TASK BODY T2A IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002A;
