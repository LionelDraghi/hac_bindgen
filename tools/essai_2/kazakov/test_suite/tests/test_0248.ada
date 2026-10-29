--
-- ACATS B44004B
--
-- Failure: Closing parenthesis ')' matching the opening one '(' at 12:24..24 is expected at 12:41
--
PROCEDURE B44004B IS

     TYPE FLOATING IS DIGITS 5;
     SUBTYPE COARSE IS FLOATING;
     SUBTYPE SHORT IS FLOATING RANGE 0.0 .. 1.0;
     NUM  : FLOATING := 1.0;
     BOOL : BOOLEAN := (NUM IN FLOATING DIGITS 4);    -- ERROR: DIGITS.


BEGIN

     IF NUM NOT IN FLOATING DIGITS 3 THEN             -- ERROR: DIGITS.
          NULL;
     ELSIF NUM IN COARSE DIGITS 3 THEN                -- ERROR: DIGITS.
          NULL;
     ELSIF NUM NOT IN COARSE DIGITS 3 THEN            -- ERROR: DIGITS.
          NULL;
     ELSE
          BOOL := (NUM IN SHORT DIGITS 4);            -- ERROR: DIGITS.
          BOOL := (NUM NOT IN SHORT DIGITS 4);        -- ERROR: DIGITS.
     END IF;

END B44004B;