--
-- ACATS B97108B
--
-- Failure: 'end select' is expected at 34:16..17
--
PROCEDURE  B97108B  IS


BEGIN


     -------------------------------------------------------------------


     DECLARE


          TASK TYPE  TT  IS
               ENTRY  A ;
          END  TT ;


          TASK BODY  TT  IS
               DUMMY : BOOLEAN := FALSE ;
          BEGIN

               SELECT
                         ACCEPT  A ;
               OR
                         ACCEPT  A ;
               ELSE
                         <<ELSE_PART>>
                         NULL ;
               OR                       -- ERROR: CANNOT FOLLOW  'ELSE'.
                         ACCEPT  A ;
               END SELECT ;

          END  TT ;


     BEGIN
          NULL ;
     END ;

     -------------------------------------------------------------------


END  B97108B ;