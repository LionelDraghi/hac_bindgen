--
-- ACATS B33201B.ADA
--
-- Failure: Semicolon is expected at 32:24
--
PROCEDURE B33201B IS

     TYPE ARR IS ARRAY (NATURAL RANGE <>) OF INTEGER;
     TYPE AA IS ACCESS ARR;

     TYPE REC IS
          RECORD
               I : INTEGER;
          END RECORD;
     TYPE AR IS ACCESS REC;

     TYPE ACC IS ACCESS INTEGER;
     TYPE AC IS ACCESS ACC;

     PACKAGE PKG IS
          TYPE PRIV IS PRIVATE;
          TYPE AP IS ACCESS PRIV;
     PRIVATE
          TYPE PRIV IS NEW INTEGER;
     END PKG;
     USE PKG;

     TASK TYPE TSK IS
     END TSK;
     TYPE ATSK IS ACCESS TSK;

     A : AA := NEW ARR RANGE 0 .. 9;       -- ERROR: RANGE CONSTRAINT
                                           -- ON ARRAY TYPE.
     R : AR := NEW REC RANGE 0 .. 9;       -- ERROR: RANGE CONSTRAINT
                                           -- ON RECORD TYPE.
     C : AC := NEW ACC RANGE 0 .. 9;       -- ERROR: RANGE CONSTRAINT
                                           -- ON ACCESS TYPE.
     P : AP := NEW PRIV RANGE 0 .. 9;      -- ERROR: RANGE CONSTRAINT
                                           -- ON PRIVATE TYPE.
     T : ATSK := NEW TSK RANGE 0 .. 9;     -- ERROR: RANGE CONSTRAINT
                                           -- ON TASK TYPE.

     TASK BODY TSK IS
     BEGIN
          NULL;
     END TSK;

BEGIN
     NULL;
END B33201B;
