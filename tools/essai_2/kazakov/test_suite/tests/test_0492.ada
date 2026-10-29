--
-- ACATS BA2001A
--
-- Failure: Procedure body stub is found outside the outmost declarative part at 25:26..33
--
PROCEDURE BA2001A IS

     PROCEDURE P IS
--          PROCEDURE Q IS SEPARATE; -- ERROR: BODY_STUB NOT IN OUTERMOST 
                                   --        DECLARATIVE PART.
     BEGIN
          NULL;
     END P;

     PACKAGE R IS
     END R;

     PACKAGE BODY R IS
--          PROCEDURE S IS SEPARATE; -- ERROR: BODY_STUB NOT IN OUTERMOST
                                   --        DECLARATIVE PART.
     END R;

BEGIN
     DECLARE
          PROCEDURE T IS SEPARATE; -- ERROR: BODY_STUB NOT IN OUTERMOST
                                   --        DECLARATIVE PART.
     BEGIN
          NULL;
     END;

END BA2001A;
