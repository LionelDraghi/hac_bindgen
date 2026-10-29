--
-- ACATS B2A003B.ADA
--
-- Failure: Semicolon is expected at 12:15
--
PROCEDURE B2A003B IS

        F : FLOAT;

BEGIN

        F := 3A.5;              -- ERROR: 3A.5
        F := 3.0A1;             -- ERROR: 3.0A1
        F := 0.3E1A;            -- ERROR: 0.3E1A
        F := 0A:2.3:;           -- ERROR: 0A:2.3:

END B2A003B;