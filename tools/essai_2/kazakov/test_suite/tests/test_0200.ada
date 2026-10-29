--
-- ACATS B37301J
--
-- Failure: No record member declarations found before 'end' at 14:21
--
PROCEDURE B37301J IS

     TYPE DAY IS (MON, TUE, WED, THU, FRI, SAT, SUN);
     TYPE VREC6(DISC : DAY) IS
          RECORD
               COMP : INTEGER;
               CASE DISC IS
                    WHEN MON =>               -- ERROR: VACUOUS LIST.
                    WHEN OTHERS =>
                         NULL;                -- OK.
               END CASE;
          END RECORD;
 
BEGIN
     NULL;
END B37301J; 