--
-- ACATS B71001B
--
-- Failure: Package body is not allowed in the package declarative items context at 12:19..22
--
PROCEDURE B71001B IS

     PACKAGE P5 IS
          PACKAGE P6 IS
               I : INTEGER;
          END P6;
          PACKAGE BODY P6 IS                 -- ERROR: PACKAGE BODY.
          END;
     END P5;

BEGIN
     NULL;
END B71001B;
