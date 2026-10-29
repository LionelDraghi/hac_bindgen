--
-- ACATS B85001E
--
-- Failure: An object or named value is expected at 14:22..31
--
PROCEDURE B85001E IS
     TYPE REC IS RECORD
          I : INTEGER;
          B : BOOLEAN;
     END RECORD;

     A : REC := (0, FALSE);
     B : REC RENAMES A;                      -- OK.
     T : REC RENAMES (0, FALSE);             -- ERROR: RENAMES LITERAL.
BEGIN
     NULL;
END B85001E;
