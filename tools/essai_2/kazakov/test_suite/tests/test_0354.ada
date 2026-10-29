--
-- ACATS B63006A
--
-- Failure: 'when' is expected after 'exception' at 12:1
--
PROCEDURE B63006A IS
     I : INTEGER;
BEGIN
     I := 12;
EXCEPTION
                                                          -- ERROR:  NO HANDLER
END B63006A;                                                      
