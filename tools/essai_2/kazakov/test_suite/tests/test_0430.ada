--
-- ACATS B85001D
--
-- Failure: An object or named value is expected at 10:22..25
--
PROCEDURE B85001D IS
     TYPE ACC IS ACCESS INTEGER;
     A : ACC := NULL;
     B : ACC RENAMES A;                  -- OK.
     T : ACC RENAMES NULL;               -- ERROR: RENAMES LITERAL.
BEGIN
     NULL;
END B85001D;
