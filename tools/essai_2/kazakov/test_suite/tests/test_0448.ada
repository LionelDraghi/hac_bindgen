--
-- ACATS B91002D
--
-- Failure: 'subtype' is unexpected inside a task public items context as found at 12:11..17
--
PROCEDURE B91002D IS

     TASK TYPE T2D IS

          ENTRY E;

          SUBTYPE S IS INTEGER;      -- ERROR: PROHIBITED IN TASK SPEC.

     END T2D;

     TASK BODY T2D IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002D;