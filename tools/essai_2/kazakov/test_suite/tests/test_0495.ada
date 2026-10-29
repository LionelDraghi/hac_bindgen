--
-- ACATS BB2003C
--
-- Failure: Others handler is not the last exception handler at 13:11..16
--
PROCEDURE BB2003C IS

     I1 : INTEGER;

BEGIN
     I1 := 1;
EXCEPTION
     WHEN OTHERS =>
          NULL;
     WHEN OTHERS =>     -- ERROR: MORE THAN ONE OTHERS HANDLER.
          NULL;

END BB2003C;
