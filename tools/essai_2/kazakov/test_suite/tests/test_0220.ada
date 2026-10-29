--
-- ACATS B35401B
--
-- Failure: '..' is expected in values range at 9:32..32
--
PROCEDURE B35401B IS

     TYPE OK IS ARRAY(1 .. 5) OF INTEGER;                              
     TYPE LINE_SIZE IS RANGE OK'RANGE;                                 -- ERROR:
                                                      -- ILLEGAL SYNTAX OK'RANGE

BEGIN
     NULL;
END B35401B;