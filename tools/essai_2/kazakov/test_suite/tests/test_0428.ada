--
-- ACATS B85001B
--
-- Failure: An object or named value is expected at 9:24..30
--
PROCEDURE B85001B IS
     A : FLOAT := 3.0;
     B : FLOAT RENAMES A;               -- OK.
     T : FLOAT RENAMES 2#11.0#;         -- ERROR: RENAMES LITERAL.
BEGIN
     NULL;
END B85001B;

