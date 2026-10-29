--
-- ACATS B91003E
--
-- Failure: 'T4' at 11:16..17 is not matched by 'T5' at 14:10..11
--
PROCEDURE B91003E IS

     TASK T4;
     TASK T5;

     TASK BODY T4 IS
     BEGIN
          NULL;
     END T5;        -- ERROR: WRONG CLOSING IDENTIFIER.

     TASK BODY T5 IS
     BEGIN
          NULL;
     END T4;        -- ERROR: WRONG CLOSING IDENTIFIER.

BEGIN

     NULL;

END B91003E;
