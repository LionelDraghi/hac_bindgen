--
-- ACATS B37310B
--
-- Success: 25:1..44:12
--
-- procedure B37310B is
--      type REC4 (DISC : DYNLETTER) is
--           record
--                case DISC is
--                     when LETTER'VAL (0)..'W'   => null;
--                     when 'Y'..LETTER'VAL (127) => null;
--                end case; end record;
--      type REC5 (DISC : SDYN) is
--           record
--                case DISC is
--                     when 'B' => null;
--                     when 'C' => null;
--                     when 'D' => null;
--                end case;
--           end record;
-- begin
--      null;
-- end B37310B;
--
PROCEDURE B37310B IS
     TYPE REC4(DISC : DYNLETTER) IS
          RECORD
               CASE DISC IS
                    WHEN LETTER'VAL(0)..'W'   => NULL;
                    WHEN 'Y'..LETTER'VAL(127) => NULL;
               END CASE; END RECORD;       -- ERROR: {3:16;13} MISSING CHOICE.

     TYPE REC5(DISC : SDYN) IS
          RECORD
               CASE DISC IS
                    WHEN 'B' => NULL;
                    WHEN 'C' => NULL;
                    WHEN 'D' => NULL;
               END CASE;                   -- ERROR: {4:16;1} MISSING CHOICES.
          END RECORD;

BEGIN
     NULL;
END B37310B;