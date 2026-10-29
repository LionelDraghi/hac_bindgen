--
-- ACATS B71001C
--
-- Failure: Function body is not allowed in the package declarative items context at 10:11
--
PROCEDURE B71001C IS

     PACKAGE P7 IS
          FUNCTION FUNC RETURN INTEGER IS        -- ERROR: IS.
          BEGIN  RETURN 5;  END FUNC;
     END P7;

BEGIN
     NULL;
END B71001C;