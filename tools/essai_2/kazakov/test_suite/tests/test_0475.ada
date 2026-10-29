--
-- ACATS B97104A
--
-- Failure: A statement is expected, 'terminate' is found instead at 18:16..24
--
PROCEDURE  B97104A  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE

     BEGIN


               TERMINATE;       -- ERROR:  TERMINATE  OUTSIDE TASK BODY.


     END  ;

     -------------------------------------------------------------------


END  B97104A ;
