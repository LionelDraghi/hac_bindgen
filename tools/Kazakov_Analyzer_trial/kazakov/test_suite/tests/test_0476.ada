--
-- ACATS B97104B
--
-- Failure: A statement is expected, 'terminate' is found instead at 23:16..24
--
PROCEDURE  B97104B  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE


          TASK TYPE  TT  IS
               ENTRY  A ;
          END  TT ;

          TASK BODY  TT  IS
          BEGIN

               TERMINATE; -- ERROR:  TERMINATE  OUTSIDE  SELECTIVE_WAIT.

          END  TT ;


     BEGIN


               NULL;


     END  ;

     -------------------------------------------------------------------


END  B97104B ;
