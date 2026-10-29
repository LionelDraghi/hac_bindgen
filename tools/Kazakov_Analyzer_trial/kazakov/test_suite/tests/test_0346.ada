--
-- ACATS B62001D
--
-- Failure: A reserved word 'FUNCTION' cannot be used as an identifier at 8:25..32
--
PROCEDURE B62001D IS

     PROCEDURE P11 (F : FUNCTION RETURN INTEGER) IS -- ERROR: FORMAL
                                                    -- FUNC PARAM.
          FUNCTION FF RETURN INTEGER IS
          BEGIN
               RETURN 0;
          END FF;
     BEGIN
          P11 (FF);           -- OPTIONAL ERROR: ACTUAL FUNCTION PARAMETER.
     END P11;

BEGIN
     NULL;
END B62001D;