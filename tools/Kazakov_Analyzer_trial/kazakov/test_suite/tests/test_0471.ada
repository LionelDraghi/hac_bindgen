--
-- ACATS B95061F
--
-- Failure: Either ';' or closing ')' matching '(' at 13:22..22 is expected after a parameter at 13:30
--
PROCEDURE B95061F IS
 
     TYPE REC ( DISC : INTEGER ) IS
          RECORD NULL; END RECORD;
 
     TASK T IS
 
          ENTRY E1 ( X : REC (DISC => 1) );     -- ERROR: DISCRIMINANT
                                                -- CONSTRAINT.
     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061F;