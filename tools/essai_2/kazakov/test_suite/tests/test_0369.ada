--
-- ACATS B67001J
--
-- Failure: An identifier is expected at 20:21..24
--
PROCEDURE B67001J IS

     GENERIC
          TYPE ELEMENT IS (<>);
     PROCEDURE P (P1 : OUT ELEMENT; P2 : ELEMENT);
     PROCEDURE P (P1 : OUT ELEMENT; P2 : ELEMENT) IS
     BEGIN
          P1 := P2;
     END P;

BEGIN

     DECLARE   -- (A)

          PROCEDURE ":=" IS NEW P                 -- ERROR: :=.
               (ELEMENT => INTEGER);

     BEGIN     -- (A)
          NULL;
     END; -- (A)

END B67001J;
