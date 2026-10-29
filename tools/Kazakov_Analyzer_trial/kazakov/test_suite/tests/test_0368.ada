--
-- ACATS B67001I
--
-- Failure: An identifier is expected at 20:31..34
--
PROCEDURE B67001I IS
     PACKAGE P IS
          TYPE LIM_PRIV IS LIMITED PRIVATE;
     PRIVATE
          TYPE LIM_PRIV IS NEW INTEGER;
     END P;
     USE P;
BEGIN

     --------------------------------------------------

     DECLARE -- (A)
          GENERIC

               WITH PROCEDURE ":=" (I1 : OUT INTEGER;      -- ERROR: :=
                                    I2 : INTEGER);

          PACKAGE PKG IS
          END PKG;

     BEGIN -- (A)
          NULL;
     END; -- (A)

END B67001I;
