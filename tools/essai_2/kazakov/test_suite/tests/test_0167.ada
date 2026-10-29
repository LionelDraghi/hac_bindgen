--
-- ACATS B23004A.ADA
--
-- Failure: ':' is expected at 9:7
--
PROCEDURE B23004A IS

     I7   : INTEGER;
     I#8  : INTEGER;   -- ERROR: # IN MIDDLE
     I9   : INTEGER;
     I'10 : INTEGER;   -- ERROR: ' IN MIDDLE
     I13  : INTEGER;
     #I14 : INTEGER;   -- ERROR: # LEADING
     I14B : INTEGER;
     'I14 : INTEGER;   -- ERROR: ' LEADING
     I21  : INTEGER;
     I22# : INTEGER;   -- ERROR: # TRAILING
     I23  : INTEGER;
     I24' : INTEGER;   -- ERROR: ' TRAILING
     I25  : INTEGER;

BEGIN

     NULL;
     I#8  := 0;     -- ERROR: # IN MIDDLE
     NULL;
     I'10 := 0;     -- ERROR: ' IN MIDDLE
     NULL;

END B23004A;