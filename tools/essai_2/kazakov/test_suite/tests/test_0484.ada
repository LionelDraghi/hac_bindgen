--
-- ACATS B97110B
--
-- Failure: Delay alternative at 40:26..30 conflicts with terminate alternative at 43:26..34
--
PROCEDURE  B97110B  IS


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
                         DELAY 1.0 ;-- (IN AN  'ACCEPT'  ALTERNATIVE)
               OR
                         TERMINATE ;-- OK.
               END SELECT ;


               SELECT
                         ACCEPT  A ;
               OR  
                         DELAY 1.0 ;
                         NULL ;
               OR
                         TERMINATE ;-- ERROR: INCOMPATIBLE WITH 
                                    --        A  'DELAY'  ALTERNATIVE.
               END SELECT ;


          END  TT ;


     BEGIN
          NULL ;
     END ;

     -------------------------------------------------------------------


END  B97110B ;
