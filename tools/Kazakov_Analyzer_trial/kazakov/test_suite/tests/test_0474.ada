--
-- ACATS B97103E
--
-- Failure: 'select' is unexpected inside a task public items context as found at 20:16..21
--
PROCEDURE  B97103E  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE


          TASK TYPE  TT2  IS

               ENTRY  A ;

               SELECT                  -- ERROR: SELECTIVE_WAIT OUTSIDE
                                       --                     TASK BODY.
                         ACCEPT  A ;
               END SELECT;

          END  TT2 ;


          TASK BODY  TT2  IS
          BEGIN
               NULL ;
          END  TT2 ;


     BEGIN


          NULL ;


     END  ;

     -------------------------------------------------------------------


END  B97103E ;
