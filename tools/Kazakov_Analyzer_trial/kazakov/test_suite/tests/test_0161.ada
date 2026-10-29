--
-- ACATS B2A003F.ADA
--
-- Failure: Semicolon is expected at 14:15
--
PROCEDURE B2A003F IS

        TYPE FIXED IS DELTA 0.1 RANGE 0.0 .. 100.0;

        F : FIXED;

BEGIN

        F := 7:7.6:;            -- ERROR: 7:7.6:
        F := 9:8.9:;            -- ERROR: 9:8.9:

END B2A003F;