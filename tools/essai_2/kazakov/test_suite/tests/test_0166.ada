--
-- ACATS B23002A.ADA
--
-- Failure: An identifier is expected at 11:6
--
PROCEDURE B23002A IS

     I_1  : INTEGER;
     I__2 : INTEGER;   -- ERROR: CONSECUTIVE UNDERSCORES.
     I3   : INTEGER;
     _I4  : INTEGER;   -- ERROR: LEADING UNDERSCORE.
     I5   : INTEGER;
     I6_  : INTEGER;   -- ERROR: TRAILING UNDERSCORE.

BEGIN

     I_1  := 1;
     I__2 := 2;    -- ERROR: CONSECUTIVE UNDERSCORES.
     I3   := 3;
     _I4  := 4;    -- ERROR: LEADING UNDERSCORE.
     I5   := 5;
     I6_  := 6;    -- ERROR: TRAILING UNDERSCORE.

END B23002A;