--
-- ACATS B24005A.ADA
--
-- Failure: Expression is expected at 14:15
--
PROCEDURE B24005A IS

        FL : FLOAT;

BEGIN

        FL := 35.;      -- ERROR: 35.
        NULL;
        FL := .68;      -- ERROR: .68
        NULL;
        FL := 71.E1;    -- ERROR: 71.E1
        NULL;
        FL := .95E1;    -- ERROR: .95E1
        NULL;
        FL := 16#.A#;   -- ERROR: 16#.A#
        NULL;
        FL := 16#A.#;   -- ERROR: 16#A.#
        NULL;

END B24005A;
