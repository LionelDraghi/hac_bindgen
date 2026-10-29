--
-- ACATS B97103A
--
-- Failure: Selective accept must have at least one accept alternative at 62:16..18
--
PROCEDURE  B97103A  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE


          PROCEDURE  B ;


          TASK TYPE  TT  IS
               ENTRY  A ;
          END  TT ;

          TASK BODY  TT  IS
          BEGIN
               NULL ;
          END  TT ;


          TASK TYPE  TT2  IS

               ENTRY  A ;
               ENTRY  B ;

          END  TT2 ;


          TASK BODY  TT2  IS
          BEGIN
               NULL ;
          END  TT2 ;


          PROCEDURE  B  IS
          BEGIN
               NULL ;
          END  B ;


     BEGIN


               SELECT
                    WHEN NOT FALSE =>  -- ERROR: SELECTIVE_WAIT OUTSIDE
                                       --   TASK BODY, OR MISSING
                                       --   ACCEPT_ALTERNATIVE.
                         DELAY 2.5 ;
               OR
                         DELAY 0.0 ;
               OR
                    WHEN TRUE =>
                         DELAY 1.0 ;
               END SELECT;


     END  ;

     -------------------------------------------------------------------


END  B97103A ;