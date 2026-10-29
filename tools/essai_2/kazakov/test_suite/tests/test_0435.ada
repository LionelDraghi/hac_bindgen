--
-- ACATS B85001L
--
-- Failure: Discriminant constraint is not allowed in renaming at 15:10..23
--
PROCEDURE B85001L IS

     TYPE REC (D : INTEGER) IS RECORD
          I : INTEGER;
          F : FLOAT;
     END RECORD;

     D0 : REC(1);

     D : REC(1) RENAMES D0;           -- ERROR: DISCRIMINANT CONSTRAINT.

BEGIN
     NULL;
END B85001L;
