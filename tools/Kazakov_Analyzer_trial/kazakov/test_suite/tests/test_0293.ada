--
-- ACATS B55B17B
--
-- Failure: 'in' or 'of' is expected at 15:10
--
PROCEDURE B55B17B IS
     TYPE REC IS
          RECORD
               I : INTEGER;
               T : CHARACTER;
          END RECORD;
     A : REC;

BEGIN
    FOR A.I IN 1 .. 5 LOOP                             -- ERROR:
         NULL;
    END LOOP;
END B55B17B;
