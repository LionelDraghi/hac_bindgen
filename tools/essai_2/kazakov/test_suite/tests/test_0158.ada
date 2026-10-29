--
-- ACATS B2A003C.ADA
--
-- Failure: Semicolon is expected at 14:15
--
PROCEDURE B2A003C IS

        TYPE FIXED IS DELTA 0.1 RANGE 0.0 .. 100.0;

        F : FIXED;

BEGIN

        F := 3A.5;              -- ERROR: 3A.5
        F := 3.0A1;             -- ERROR: 3.0A1
        F := 0.3E1A;            -- ERROR: 0.3E1A
        F := 0A:2.3:;           -- ERROR: 0A:2.3:

END B2A003C;