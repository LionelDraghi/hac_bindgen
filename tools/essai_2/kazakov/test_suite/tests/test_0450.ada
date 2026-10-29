--
-- ACATS B91002F
--
-- Failure: 'type' is unexpected inside a task public items context as found at 12:11..14
--
PROCEDURE B91002F IS

     TASK TYPE T2F IS

          ENTRY E;

          TYPE R IS                  -- ERROR: PROHIBITED IN TASK SPEC.
               RECORD
                    B : BOOLEAN;
               END RECORD;

     END T2F;

     TASK BODY T2F IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002F;