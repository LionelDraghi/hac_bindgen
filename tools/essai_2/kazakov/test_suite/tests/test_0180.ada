--
-- ACATS B28001C.ADA
--
-- Failure: Closing parenthesis ')' matching the opening one '(' at 19:8..8 is expected at 19:16
--
PROCEDURE B28001C IS

     FUNCTION P RETURN INTEGER IS
     BEGIN
          RETURN 1;
     END P;

     PROCEDURE P (X : INTEGER) IS
     BEGIN
          NULL;
     END P;

BEGIN
     P (PRAGMA HEATHER_TILTON; 1);         -- ERROR: POSITION OF PRAGMA.
     P (2);
     NULL;
END B28001C;