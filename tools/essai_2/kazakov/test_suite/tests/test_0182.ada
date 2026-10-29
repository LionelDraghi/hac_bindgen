--
-- ACATS B28001R.ADA
--
-- Failure: No record member declarations found before 'end' at 11:11
--
PROCEDURE B28001R IS

     TYPE REC1 IS
          RECORD
               PRAGMA LIST (ON);
          END RECORD;           -- ERROR: MISSING COMPONENT DECLARATION.

BEGIN
     NULL;
END B28001R;
