--
-- ACATS B61005A
--
-- Failure: No default value is allowed for parameters in the out mode at 13:41..42
--
PROCEDURE B61005A IS

--   PROCEDURE TEST_INOUT(I : IN OUT INTEGER := 12) IS     -- ERROR:
--        BEGIN
--             NULL;
--        END;

     PROCEDURE TEST_OUT(I : OUT INTEGER := 12) IS          -- ERROR:
          BEGIN
               I := 12;
          END;
BEGIN
     NULL;
END B61005A;
