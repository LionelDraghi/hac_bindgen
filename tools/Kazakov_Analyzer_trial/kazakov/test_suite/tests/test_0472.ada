--
-- ACATS B95061G
--
-- Failure: Semicolon is expected at 10:34
--
PROCEDURE B95061G IS
 
     TASK T IS

          ENTRY E1 (X : INTEGER) RETURN INTEGER;       -- ERROR: RETURN.

     END T;
 
     TASK BODY T IS
     BEGIN
          NULL;
     END T;
 
BEGIN
     NULL;
END B95061G;