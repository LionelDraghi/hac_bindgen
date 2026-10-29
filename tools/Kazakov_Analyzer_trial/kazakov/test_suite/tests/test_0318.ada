--
-- ACATS B57001A
--
-- Failure: 'exit' ouside any loop is found at 16:11..14
--
PROCEDURE  B57001A  IS
BEGIN


     BEGIN

          FOR  I  IN  1..11  LOOP
               EXIT ;                        -- OK
          END LOOP;

          EXIT ;                             -- ERROR: OUTSIDE LOOP BODY

     END ;


     BEGIN

          FOR  I  IN  CHARACTER  LOOP
               EXIT ;                        -- OK
          END LOOP;

          EXIT ;                             -- ERROR: OUTSIDE LOOP BODY

     END ;


     BEGIN

          FOR  I  IN  1..11  LOOP
               EXIT WHEN I>22 ;              -- OK
          END LOOP;

          EXIT WHEN 7>3 ;                    -- ERROR: OUTSIDE LOOP BODY

     END ;


     BEGIN

          LOOP_ID :
          FOR  I  IN  1..11  LOOP
               EXIT LOOP_ID ;                -- OK
          END LOOP  LOOP_ID ;

          EXIT LOOP_ID ;                     -- ERROR: OUTSIDE LOOP BODY

     END ;


     BLOCK_ID :
     BEGIN

          FOR  I  IN  1..11  LOOP
               EXIT WHEN  I = 11 ;           -- OK
          END LOOP;

          EXIT BLOCK_ID ;                    -- ERROR: OUTSIDE LOOP BODY

     END  BLOCK_ID ;


END B57001A ;
