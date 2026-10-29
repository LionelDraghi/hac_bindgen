--
-- ACATS B37004C
--
-- Failure: No record member declarations found before 'end' at 9:24
--
PROCEDURE B37004C IS

     SUBTYPE S1 IS INTEGER RANGE 1 .. 1;
     TYPE R1 IS RECORD END RECORD;               -- ERROR: 

BEGIN
     NULL;
END B37004C;
