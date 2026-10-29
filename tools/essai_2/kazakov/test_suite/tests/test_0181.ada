--
-- ACATS B28001E.ADA
--
-- Failure: A reserved word 'PRAGMA' cannot be used as an identifier at 8:19..24
--
PROCEDURE B28001E IS

     PROCEDURE P (PRAGMA PHIL_BRASHEAR; X : INTEGER) IS        -- ERROR:
     BEGIN                                                   -- POSITION
          NULL;                                            -- OF PRAGMA.
     END P;

BEGIN
     NULL;
END B28001E;
