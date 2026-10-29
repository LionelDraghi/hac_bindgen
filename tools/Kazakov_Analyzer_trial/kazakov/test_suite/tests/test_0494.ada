--
-- ACATS BB2003B
--
-- Failure: Others handler is not the last exception handler at 15:16..21
--
PROCEDURE BB2003B IS

     I1 : INTEGER;

     PROCEDURE P IS
          IA : INTEGER;
     BEGIN
          IA := 1;
     EXCEPTION
          WHEN OTHERS =>            -- ERROR: 'OTHERS' NOT LAST.
               NULL;
          WHEN CONSTRAINT_ERROR =>
               NULL;
     END P;

BEGIN
     NULL;

END BB2003B;
