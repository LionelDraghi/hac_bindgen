--
-- ACATS B64004B
--
-- Failure: Operand is expected at 22:11
--
PROCEDURE B64004B IS

     I    : INTEGER;

     PROCEDURE P (X1: INTEGER; X2: INTEGER := 2; X3: INTEGER := 3) IS
     BEGIN
          NULL;
     END P;

     FUNCTION F (X1: INTEGER := 1; X2: INTEGER) RETURN INTEGER IS
     BEGIN
          RETURN 1;
     END F;

BEGIN

     P (1,,3);           -- ERROR: (A).
     NULL;

END B64004B;
