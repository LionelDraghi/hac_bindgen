--
-- ACATS B57001C
--
-- Failure: 'exit' ouside any loop is found at 22:26..29
--
PROCEDURE  B57001C  IS
BEGIN

     BEGIN

          FOR  I  IN  1..11  LOOP

               NULL ;

               DECLARE

                    TASK  TK ;

                    TASK BODY  TK  IS
                    BEGIN
                         NULL ;
                         EXIT ;         -- ERROR: ACROSS TASK BODY WALLS
                    END  TK ;

               BEGIN
                    EXIT ;              -- OK.
               END;

          END LOOP;


          OUTER_L :
          FOR  I  IN  CHARACTER  LOOP

               NULL ;

               DECLARE

                    TASK  TK   IS
                         ENTRY  E1 ;
                         ENTRY  E2 ;
                    END  TK ;

                    TASK BODY  TK  IS
                    BEGIN
                         LOOP_ID :
                         LOOP
                              SELECT

                                   ACCEPT  E1  DO
                                        EXIT  WHEN  I = 'B' ; -- ERROR:
                                        --    ACROSS 'ACCEPT STATEMENT'
                                        --    WALLS.
                                   END  E1 ;

                                   EXIT  WHEN  I= 'B' ;       -- OK.

                              OR

                                   ACCEPT  E2  DO
                                        EXIT  LOOP_ID ;        -- ERROR:
                                        --    ACROSS  'ACCEPT STATEMENT'
                                        --    WALLS.
                                   END  E2 ;

                                   EXIT LOOP_ID  WHEN I = 'B' ;-- OK.
                                   EXIT OUTER_L  WHEN I = 'B' ;-- ERROR:
                                   --    ACROSS TASK BODY WALLS


                              END SELECT;
                         END LOOP  LOOP_ID ;
                         EXIT ;         -- ERROR: ACROSS TASK BODY WALLS
                    END  TK ;

               BEGIN
                    EXIT ;              -- OK.
               END;

          END LOOP  OUTER_L ;


     END ;


END B57001C ;
