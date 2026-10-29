--
-- ACATS B97110A
--
-- Failure: Terminate alternative at 40:26..34 conflicts with delay alternative at 42:26..30
--
PROCEDURE  B97110A  IS


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
                         TERMINATE ;
               OR
                         ACCEPT  A ;
                         DELAY 1.0 ;-- OK (IN AN  'ACCEPT'  ALTERNATIVE)
               END SELECT ;


               SELECT
                         ACCEPT  A ;
               OR  
                         TERMINATE ;
               OR
                         DELAY 1.0 ;-- ERROR: INCOMPATIBLE WITH 
                                    --              'TERMINATE' .
                         NULL ;
               END SELECT ;

          END  TT ;


     BEGIN
          NULL ;
     END ;

     -------------------------------------------------------------------


END  B97110A ;
