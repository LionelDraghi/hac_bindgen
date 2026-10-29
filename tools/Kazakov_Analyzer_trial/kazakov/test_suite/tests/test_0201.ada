--
-- ACATS B37301I
--
-- Failure: Others choice is not the last choice at 16:21..24
--
PROCEDURE B37301I IS
 
     TYPE DAY IS (SUN,MON,TUE,WED,THU,FRI,SAT);
 
     TYPE VREC1(DISC : DAY) IS
          RECORD
               COMP : INTEGER;
               CASE DISC IS
                    WHEN OTHERS =>            -- ERROR: OTHERS NOT LAST.
                         WRONG : INTEGER;
                    WHEN MON =>
                         VAR1 : INTEGER;
               END CASE;
          END RECORD;
 
     TYPE VREC2(DISC : DAY) IS
          RECORD
               COMP : INTEGER;
               CASE DISC IS 
                    WHEN MON =>
                         VAR1 : INTEGER;
                    WHEN OTHERS =>            -- ERROR: OTHERS NOT LAST.
                         WRONG : INTEGER;
                    WHEN TUE =>
                         VAR2 : INTEGER;
               END CASE;  
          END RECORD;
 
     TYPE VREC3(DISC : DAY) IS
          RECORD
               COMP : INTEGER;
               CASE DISC IS
                    WHEN MON =>
                         VAR1 : INTEGER;
                    WHEN OTHERS | TUE =>      -- ERROR: OTHERS NOT 
                                              --   ALONE.
                         WRONG : INTEGER;
               END CASE;
          END RECORD;
 
     TYPE VREC4(DISC : DAY) IS
          RECORD
               COMP : INTEGER;
               CASE DISC IS
                    WHEN MON => 
                         VAR1 : INTEGER;
                    WHEN TUE | OTHERS | WED => -- ERROR: OTHERS NOT 
                                               --   ALONE.
                         WRONG : INTEGER;
               END CASE;
          END RECORD;
 
     TYPE VREC5(DISC : DAY) IS
          RECORD
               COMP : INTEGER;
               CASE DISC IS
                    WHEN MON =>
                         VAR1 : INTEGER;
                    WHEN TUE | OTHERS =>      -- ERROR: OTHERS NOT 
                                              --   ALONE.
                         WRONG : INTEGER;
               END CASE;
          END RECORD;
 
BEGIN
     NULL;
END B37301I;
