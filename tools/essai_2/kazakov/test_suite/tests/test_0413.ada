--
-- ACATS B71001F
--
-- Failure: Task body is not allowed in the package declarative items context at 11:11
--
PROCEDURE B71001F IS

     PACKAGE P IS
          TASK T;
          TASK BODY T IS                     -- ERROR: BODY.
          BEGIN NULL; END T;
     END P;

BEGIN
     NULL;
END B71001F;
