--
-- ACATS B71001N
--
-- Failure: Package body is not allowed in the package declarative items context at 14:19..22
--
PROCEDURE B71001N IS

     PACKAGE P5 IS
          GENERIC
          PACKAGE P6 IS
               I : INTEGER;
          END P6;

          PACKAGE BODY P6 IS                 -- ERROR: PACKAGE BODY.
          END;
     END P5;

BEGIN
     NULL;
END B71001N;