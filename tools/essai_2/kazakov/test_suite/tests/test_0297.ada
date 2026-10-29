--
-- ACATS B56001E
--
-- Failure: 'declare', 'begin', 'loop', 'parallel' or 'while' is expected at 9:15
--
PROCEDURE B56001E IS
BEGIN

     BEGIN Y: INTEGER; Y := 5; END;          -- ERROR: DCL AS STMT.

END B56001E;