--
-- ACATS B97111A
--
-- Failure: Delay alternative at 43:26..30 conflicts with else part at 47:16..19
--
PROCEDURE  B97111A  IS


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
                         DELAY 1.0 ;      -- (IN AN ACCEPT ALTERNATIVE)
               OR
                         ACCEPT  A ;
               ELSE                       -- OK.
                         NULL ;
               END SELECT ;


               SELECT
                         ACCEPT  A ;
               OR  
                         DELAY 1.0 ;
               OR
                         ACCEPT  A ;

               ELSE   -- ERROR: INCOMPATIBLE WITH  'DELAY'  ALTERNATIVE.

                         NULL ;
               END SELECT ;

          END  TT ;


     BEGIN
          NULL ;
     END ;

     -------------------------------------------------------------------


END  B97111A ;
