--
-- ACATS B95061A
--
-- Failure: A reserved word 'ARRAY' cannot be used as an identifier at 10:24..28
--
PROCEDURE B95061A IS
 
     TASK T IS
 
          ENTRY E9 (X: ARRAY(1..10) OF INTEGER);  -- ERROR: FORMAL ARRAY
                                                  -- TYPE DEFINITION.
     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061A;