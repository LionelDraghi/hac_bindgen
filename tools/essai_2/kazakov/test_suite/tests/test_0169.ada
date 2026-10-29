--
-- ACATS B24001A.ADA
--
-- Failure: Expression is expected at 21:12
--
PROCEDURE B24001A IS

     I1, I2, I3 : INTEGER;

BEGIN

     I1 := 12__3;       -- ERROR: CONSECUTIVE UNDERSCORES WITHIN AN
                        --        INTEGER LITERAL
     NULL;
     I2 := 12E0__1;     -- ERROR: CONSECUTIVE UNDERSCORES WITHIN AN
                        --        INTEGER LITERAL
     NULL;
     I2 := 16#1__A#;    -- ERROR: CONSECUTIVE UNDERSCORES WITHIN AN
                        --        INTEGER LITERAL
     NULL;
     I2 := _12;         -- ERROR: UNDERSCORE LEADS AN INTEGER LITERAL
     NULL;
     I3 := 12_;         -- ERROR: UNDERSCORE TRAILS AN INTEGER LITERAL
     NULL;
     I3 := 12E1_;       -- ERROR: UNDERSCORE TRAILS AN INTEGER LITERAL
     NULL;
     I2 := 2_E1;        -- ERROR: UNDERSCORE ADJACENT TO E
     NULL;
     I2 := 2E_1;        -- ERROR: UNDERSCORE ADJACENT TO E
     NULL;
     I2 := 2E+_1;       -- ERROR: UNDERSCORE ADJACENT TO +
     NULL;
     I2 := 2E_+1;       -- ERROR: UNDERSCORE ADJACENT TO +
     NULL;
     I2 := 2E-_1;       -- ERROR: UNDERSCORE ADJACENT TO -
     NULL;
     I2 := 2E_-1;       -- ERROR: UNDERSCORE ADJACENT TO -
     NULL;
     I1 := 16_#D#;      -- ERROR: UNDERSCORE ADJACENT TO #
     NULL;
     I2 := 16#_D#;      -- ERROR: UNDERSCORE ADJACENT TO #
     NULL;
     I2 := 16#D_#;      -- ERROR: UNDERSCORE ADJACENT TO #
     NULL;
     I2 := 16#D#_;      -- ERROR: UNDERSCORE ADJACENT TO #
     NULL;

END B24001A;

