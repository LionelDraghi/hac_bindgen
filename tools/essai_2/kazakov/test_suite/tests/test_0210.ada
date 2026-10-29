--
-- ACATS B37004G
--
-- Failure: Record component cannot be an anonymous array as found at 11:16..20
--
PROCEDURE B37004G IS

     SUBTYPE S1 IS INTEGER RANGE 1 .. 1;

     TYPE REC IS RECORD
          C1 : ARRAY (S1) OF S1;        -- ERROR: ANONYMOUS TYPE
     END RECORD;

BEGIN
     NULL;

END B37004G;