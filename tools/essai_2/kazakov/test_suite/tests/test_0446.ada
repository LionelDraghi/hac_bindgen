--
-- ACATS B91002B
--
-- Failure: A task item declaration is expected at 12:11
--
PROCEDURE B91002B IS

     TASK TYPE T2B IS

          ENTRY E;

          N : CONSTANT := 1;         -- ERROR: PROHIBITED IN TASK SPEC.

     END T2B;

     TASK BODY T2B IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002B;