--
-- ACATS B91001B
--
-- Failure: Semicolon is expected at 8:13
--
PROCEDURE B91001B IS

     TASK T (I : IN OUT INTEGER);       -- ERROR: PARAMETER LIST
                                        --        PROHIBITED.
     TASK BODY T IS
     BEGIN
          NULL;
     END T;

BEGIN
     NULL;
END B91001B;
