--
-- ACATS B71001O
--
-- Failure: Procedure body is not allowed in the package declarative items context at 12:11
--
PROCEDURE B71001O IS

     PACKAGE P7 IS
          GENERIC PROCEDURE PROC;

          PROCEDURE PROC IS                  -- ERROR: IS.
          BEGIN NULL; END PROC;
     END P7;

BEGIN
     NULL;
END B71001O;