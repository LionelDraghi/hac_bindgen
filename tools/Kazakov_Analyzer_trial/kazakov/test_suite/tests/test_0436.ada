--
-- ACATS B85010A
--
-- Failure: An identifier is expected at 14:28
--
PROCEDURE B85010A IS

     PACKAGE PACK1 IS
          TYPE COLORS IS (RED, BLUE, GREEN);
     END PACK1;

     PACKAGE PACK2 RENAMES PACK1;                   -- OK.

     PACKAGE PACK6 RENAMES 12_000;                  -- ERROR: LITERAL

BEGIN
     NULL;
END B85010A;
