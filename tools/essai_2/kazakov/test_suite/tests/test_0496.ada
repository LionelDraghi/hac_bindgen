--
-- ACATS BB3002A
--
-- Failure: Re-raise statement is specified outside an exception handler at 10:11..15
--
PROCEDURE BB3002A IS

BEGIN
     BEGIN
          RAISE;          -- ERROR: NON-SPECIFIC RAISE OUTSIDE HANDLER.
     EXCEPTION
          WHEN CONSTRAINT_ERROR =>
               NULL;
          WHEN OTHERS =>

               DECLARE
                    PROCEDURE P IS
                    BEGIN
                         RAISE;  -- ERROR: 'RAISE;' IN PROCEDURE.
                    END P;

                    PACKAGE Q IS
                         I : INTEGER;
                    END Q;

                    PACKAGE BODY Q IS
                    BEGIN
                          RAISE;  -- ERROR: 'RAISE;' IN PACKAGE.
                    END Q;
               BEGIN
                    NULL;
               END ;
     END ;

END BB3002A;
