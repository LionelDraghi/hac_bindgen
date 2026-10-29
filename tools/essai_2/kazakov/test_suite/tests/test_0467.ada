--
-- ACATS B95061B
--
-- Failure: Either ';' or closing ')' matching '(' at 10:22..22 is expected after a parameter at 10:34
--
PROCEDURE B95061B IS
 
     TASK T IS
 
          ENTRY E1 ( X : INTEGER RANGE 1..10 );     -- ERROR: RANGE.
 
     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061B;