--
-- ACATS B95061C
--
-- Failure: Either ';' or closing ')' matching '(' at 10:22..22 is expected after a parameter at 10:32
--
PROCEDURE B95061C IS
 
     TASK T IS
 
          ENTRY E1 ( X : FLOAT DIGITS 6 );     -- ERROR: DIGITS.
 
     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061C;