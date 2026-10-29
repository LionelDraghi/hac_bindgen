--
-- ACATS B52002F
--
-- Failure: Left part of assignment cannot be an attribute as found at 17:8..8
--
PROCEDURE B52002G IS

     TYPE DRT (I : INTEGER := 0) IS
          RECORD
               B : BOOLEAN;
          END RECORD;

     DR : DRT;

BEGIN

     DR'SIZE := 1;      -- ERROR: ATTRIBUTE ON LEFT.

END B52002G ;
