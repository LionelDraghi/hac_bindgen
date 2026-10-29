--
-- ACATS B56001G
--
-- Failure: 'when' is expected after 'exception' at 12:1..5
--
PROCEDURE B56001G IS
BEGIN

     L7: BEGIN
          NULL;
     EXCEPTION
     END L7;                                 -- ERROR: EMPTY EXCEPTION.

END B56001G;
