--
-- ACATS B64003A
--
-- Failure: A positional parameter appears after a named one at 26:21..21
--
PROCEDURE B64003A IS

     I, J : INTEGER := 0;

     PROCEDURE P (X1 : INTEGER; X2 : IN OUT INTEGER;
          X3 : OUT INTEGER) IS
     BEGIN
          NULL;
     END P;

     FUNCTION F (X1, X2 : INTEGER) RETURN INTEGER IS
     BEGIN
          RETURN 2;
     END F;

BEGIN

     -- (A)
--   P (X1 => 1, X2 => I, J);      -- ERROR: POSITIONAL AFTER NAMED.
     NULL;
     P (1, X2 => I, J);            -- ERROR: POSITIONAL AFTER NAMED.
     NULL;
     I := F (X1 => 1, 2);          -- ERROR: POSITIONAL AFTER NAMED.
     NULL;

     -- (B)
     P (X2 => I, J, X3 => J);      -- ERROR: X2 SPECIFIED TWICE.
     NULL;
     I := F (1, X2 => 2, X1 => 1); -- ERROR: X1 SPECIFIED TWICE.
     NULL;

     -- (C)
     P (X1 => 1, X2 => J, X1 => I);     -- ERROR: X1 SPECIFIED TWICE.
     NULL;
     I := F (X1 => 1, X2 => 2, X1 => 1);-- ERROR: X1 SPECIFIED TWICE.
     NULL;

     -- (D)
     P (I => 1, X2 => I, X3 => J); -- ERROR: I NOT A FORMAL.
     NULL;
     I := F (F => 1, X2 => 2);     -- ERROR: F NOT A FORMAL.
     NULL;

     -- (E)
     P (1, X1 => 1, X2 => J);      -- ERROR: X1 SPECIFIED TWICE.
     NULL;
     I := F (I, J, X2 => J);       -- ERROR: X2 SPECIFIED TWICE.
     NULL;

END B64003A;
