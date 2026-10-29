--
-- ACATS B97104C
--
-- Failure: A statement is expected, 'terminate' is found instead at 33:16..24
--
PROCEDURE  B97104C  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE


          PROCEDURE  B ;


          TASK TYPE  TT  IS
               ENTRY  A ;
          END  TT ;

          TASK BODY  TT  IS
          BEGIN

               NULL;

          END  TT ;


          PROCEDURE  B  IS
          BEGIN
               TERMINATE;       -- ERROR:  TERMINATE  OUTSIDE TASK BODY.
               NULL ;
          END  B ;


     BEGIN


               NULL;


     END  ;

     -------------------------------------------------------------------


END  B97104C ;
