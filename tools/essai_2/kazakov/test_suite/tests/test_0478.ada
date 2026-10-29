--
-- ACATS B97104D
--
-- Failure: A statement is expected, 'terminate' is found instead at 30:21..29
--
PROCEDURE  B97104D  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE


          TASK  TT  IS
               ENTRY  A ;
          END  TT ;


          TASK BODY  TT  IS

               TASK  INNERTASK  IS
                    ENTRY  I ;
               END  INNERTASK ;

               TASK BODY  INNERTASK  IS
               BEGIN
                    ACCEPT  I ;
                    TERMINATE; -- ERROR:  TERMINATE  OUTSIDE  SELECTIVE_
                               --                                  WAIT.
               END  INNERTASK ;


          BEGIN

               ACCEPT  A ;

          END  TT ;

     BEGIN

          NULL ;

     END  ;

     -------------------------------------------------------------------


END  B97104D ;
