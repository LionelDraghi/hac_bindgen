--
-- ACATS B85001B
--
-- Failure: An object or named value is expected at 9:26..26
--
PROCEDURE B85001A IS
     A : INTEGER := 3;
     B : INTEGER RENAMES A;               -- OK.
     T : INTEGER RENAMES 0;               -- ERROR: RENAMES LITERAL
BEGIN
     NULL;
END B85001A;


