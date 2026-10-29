--
-- ACATS B9A001A
--
-- Failure: An identifier is expected at 33:16..16
--
PROCEDURE  B9A001A  IS
BEGIN


     -------------------------------------------------------------------


     DECLARE


          TASK TYPE  T_TYPE  IS
               ENTRY  E ;
          END  T_TYPE ;


          TASK BODY  T_TYPE  IS
               BUSY : BOOLEAN := FALSE ;
          BEGIN

               NULL;
               ABORT  T_TYPE ;      -- OK (THE OBJECT).

          END  T_TYPE ;


     BEGIN

          ABORT ;                   -- ERROR: NO TASK OBJECT.

     END ;


     -------------------------------------------------------------------


END  B9A001A ;
