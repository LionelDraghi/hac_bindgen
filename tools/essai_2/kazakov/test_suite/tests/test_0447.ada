--
-- ACATS B91002C
--
-- Failure: 'type' is unexpected inside a task public items context as found at 12:11..14
--
PROCEDURE B91002C IS

     TASK TYPE T2C IS

          ENTRY E;

          TYPE A IS ACCESS INTEGER;  -- ERROR: PROHIBITED IN TASK SPEC.

     END T2C;

     TASK BODY T2C IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002C;