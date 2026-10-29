--
-- ACATS B95061E
--
-- Failure: Either ';' or closing ')' matching '(' at 12:22..22 is expected after a parameter at 12:29
--
PROCEDURE B95061E IS
 
     TYPE ARR IS ARRAY ( INTEGER RANGE <> ) OF INTEGER;
 
     TASK T IS
 
          ENTRY E1 ( X : ARR(1..10) );     -- ERROR: INDEX CONSTRAINT.
 
     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061E;