--
-- ACATS B71001L
--
-- Failure: Task body is not allowed in the package declarative items context at 12:11
--
PROCEDURE B71001L IS

     GENERIC
     PACKAGE P IS
          TASK T;
          TASK BODY T IS                     -- ERROR: BODY.
          BEGIN NULL; END T;
     END P;

BEGIN
     NULL;
END B71001L;
