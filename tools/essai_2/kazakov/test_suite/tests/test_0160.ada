--
-- ACATS B2A003E.ADA
--
-- Failure: Semicolon is expected at 12:15
--
PROCEDURE B2A003E IS

        F : FLOAT;

BEGIN

        F := 7:7.6:;            -- ERROR: 7:7.6:
        F := 9:8.9:;            -- ERROR: 9:8.9:

END B2A003E;