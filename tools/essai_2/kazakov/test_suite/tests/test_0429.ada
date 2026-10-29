--
-- ACATS B85001C
--
-- Failure: An object or named value is expected at 9:25..31
--
PROCEDURE B85001C IS
     A : CONSTANT STRING := "THIS IS ONLY A TEST";
     B : STRING RENAMES A;               -- OK.
     T : STRING RENAMES "OH NO";         -- ERROR: RENAMES LITERAL.
BEGIN
     NULL;
END B85001C;
