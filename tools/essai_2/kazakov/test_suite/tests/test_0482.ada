--
-- ACATS B97109A
--
-- Failure: Terminate alternative at 30:26..34 conflicts with else part at 33:16..19
--
PROCEDURE  B97109A  IS


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
               ELSE           -- ERROR: INCOMPATIBLE WITH  'TERMINATE' .
                         NULL ;
               END SELECT ;

          END  TT ;


     BEGIN
          NULL ;
     END ;

     -------------------------------------------------------------------


END  B97109A ;
