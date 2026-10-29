--
-- ACATS B24005B.ADA
--
-- Failure: Expression is expected at 16:15
--
PROCEDURE B24005B IS

        TYPE FIXED IS DELTA 0.1 RANGE 0.0 .. 100.0;

        FX : FIXED;

BEGIN

        FX := 35.;      -- ERROR: 35.
        NULL;
        FX := .68;      -- ERROR: .68
        NULL;
        FX := 71.E1;    -- ERROR: 71.E1
        NULL;
        FX := .95E1;    -- ERROR: .95E1
        NULL;
        FX := 16#.A#;   -- ERROR: 16#.A#
        NULL;
        FX := 16#A.#;   -- ERROR: 16#A.#
        NULL;

END B24005B;