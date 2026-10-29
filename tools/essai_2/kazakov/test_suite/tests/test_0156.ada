--
-- ACATS B2A003A.ADA
--
-- Failure: Semicolon is expected at 12:15
--
PROCEDURE B2A003A IS

        I  : INTEGER;

BEGIN

        I := 2:2:;              -- ERROR: 2:2:
        I := 3:3:;              -- ERROR: 3:3:
        I := 4:4:;              -- ERROR: 4:4:
        I := 5:5:;              -- ERROR: 5:5:
        I := 6:6:;              -- ERROR: 6:6:
        I := 7:7:;              -- ERROR: 7:7:
        I := 8:8:;              -- ERROR: 8:8:
        I := 9:9:;              -- ERROR: 9:9:
        I := 10:A:;             -- ERROR: 10:A:
        I := 11:B:;             -- ERROR: 11:B:
        I := 12:C:;             -- ERROR: 12:C:
        I := 13:D:;             -- ERROR: 13:D:
        I := 14:E:;             -- ERROR: 14:E:
        I := 15:F:;             -- ERROR: 15:F:
        I := 16:G:;             -- ERROR: 16:G:

END B2A003A;
