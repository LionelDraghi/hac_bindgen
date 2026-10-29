--
-- ACATS B91002H
--
-- Failure: 'function' is unexpected inside a task public items context as found at 12:11..18
--
PROCEDURE B91002H IS

     TASK TYPE T2H IS

          ENTRY E;

          FUNCTION F RETURN INTEGER; -- ERROR: PROHIBITED IN TASK SPEC.

     END T2H;

     TASK BODY T2H IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002H;