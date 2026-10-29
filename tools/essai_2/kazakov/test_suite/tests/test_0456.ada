--
-- ACATS B91002L
--
-- Failure: A task item declaration is expected at 12:11
--
PROCEDURE B91002L IS

     TASK TYPE T2L IS

          ENTRY E;

          EX : EXCEPTION;            -- ERROR: PROHIBITED IN TASK SPEC.

     END T2L;

     TASK BODY T2L IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002L;