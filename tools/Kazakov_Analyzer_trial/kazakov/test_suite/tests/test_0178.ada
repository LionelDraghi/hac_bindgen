--
-- ACATS B28001A.ADA
--
-- Failure: Semicolon is expected at 21:22
--
PROCEDURE B28001A IS

     A : INTEGER := 1;

     FUNCTION P RETURN INTEGER IS
     BEGIN
          RETURN 1;
     END P;

     PROCEDURE P IS
     BEGIN
          NULL;
     END P;

BEGIN
     A := 2 * PRAGMA THOMAS_NORRIS;        -- ERROR: POSITION OF PRAGMA.
     P;
     NULL;
END B28001A;
