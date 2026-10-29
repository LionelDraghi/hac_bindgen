--
-- ACATS B28001B.ADA
--
-- Failure: Semicolon is expected at 21:18
--
PROCEDURE B28001B IS

     B : INTEGER;

     FUNCTION P RETURN INTEGER IS
     BEGIN
          RETURN 1;
     END P;

     PROCEDURE P IS
     BEGIN
          NULL;
     END P;

BEGIN
     B := PRAGMA LIST (ON);                -- ERROR: POSITION OF PRAGMA.
     P;
     NULL;
END B28001B;
