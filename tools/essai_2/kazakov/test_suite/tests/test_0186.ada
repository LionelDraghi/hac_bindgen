--
-- ACATS B28001V.ADA
--
-- Failure: 'when' is expected after 'is' at 14:1..20
--
PROCEDURE B28001V IS

     TYPE DEVICE IS (PRINTER, DISK, TERMINAL);

     TYPE PERIPHERAL (UNIT : DEVICE := TERMINAL) IS
          RECORD
               LINE : STRING (1 .. 80);
               CASE UNIT IS
                    PRAGMA LIST (ON);
               END CASE;                      -- ERROR: MISSING VARIANT.
          END RECORD;

BEGIN
     NULL;
END B28001V;