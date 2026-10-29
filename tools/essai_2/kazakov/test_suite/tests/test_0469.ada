--
-- ACATS B95061D
--
-- Failure: Either ';' or closing ')' matching '(' at 10:22..22 is expected after a parameter at 10:35
--
PROCEDURE B95061D IS
 
     TASK T IS
 
          ENTRY E1 ( X : DURATION DELTA 0.01 );     -- ERROR: DELTA.
 
     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061D;