--
-- ACATS B97104E
--
-- Failure: A statement is expected, 'terminate' is found instead at 35:21..29
--
PROCEDURE  B97104E  IS
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
                    NULL;
               END  INNERTASK ;

               PROCEDURE  WITHIN_OUTER_TASK_BODY  IS
               BEGIN

                    TERMINATE; -- ERROR:  TERMINATE  OUTSIDE  SELECTIVE_
                               --                                  WAIT.
                    
               END  WITHIN_OUTER_TASK_BODY ;

          BEGIN

               ACCEPT  A ;

          END  TT ;

     BEGIN

          NULL ;

     END  ;

     -------------------------------------------------------------------


END  B97104E ;
