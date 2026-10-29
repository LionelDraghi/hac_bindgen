--
-- ACATS B71001U
--
-- Failure: Procedure body is not allowed in the package declarative items context at 14:11
--
PROCEDURE B71001U IS

     GENERIC
     PACKAGE P7 IS
          GENERIC
          PROCEDURE PROC;

          PROCEDURE PROC IS                  -- ERROR: IS.
          BEGIN NULL; END PROC;
     END P7;

BEGIN
     NULL;
END B71001U;
