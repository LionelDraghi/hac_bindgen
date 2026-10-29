--
-- ACATS B2A003D.ADA
--
-- Failure: Semicolon is expected at 12:15
--
PROCEDURE B2A003D IS

        I  : INTEGER;

BEGIN

        I := 3A;                -- ERROR: 3A
        I := 0A:2:;             -- ERROR: 0A:2:
        I := 2E1A;              -- ERROR: 2E1A

END B2A003D;