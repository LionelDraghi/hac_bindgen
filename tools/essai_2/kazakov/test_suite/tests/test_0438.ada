--
-- ACATS B91001C
--
-- Failure: A reserved word 'TYPE' cannot be used as an identifier at 8:16..19
--
PROCEDURE B91001C IS

     PROCEDURE TYPE P;             -- ERROR: PROCEDURE TYPE
                                   --        DECLARATION PROHIBITED.

BEGIN
     NULL;
END B91001C;
