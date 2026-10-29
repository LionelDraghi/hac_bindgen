--
-- ACATS B38003C
--
-- Failure: Either ';' or closing ')' matching '(' at 20:22..22 is expected after a parameter at 20:47
--
PROCEDURE B38003C IS

     TYPE ARR IS ARRAY(INTEGER RANGE <>) OF INTEGER;
     TYPE ARR_NAME IS ACCESS ARR(1..5);               -- 1.
     SUBTYPE SUB_ARR IS ARR(1..5);                    -- 3.
     TYPE ARR_NAME3 IS ACCESS SUB_ARR;                -- 3.

     TYPE REC(DISC : INTEGER) IS
          RECORD
               NULL;
          END RECORD;

     TYPE REC_NAME IS ACCESS REC(5);                  -- 2.

     PROCEDURE PROC1 (PARM1 : IN OUT ARR_NAME (1..5);      -- ERROR: F1.
                      PARM2 : IN OUT REC_NAME (5);         -- ERROR: F2.
                      PARM3 : IN OUT ARR_NAME3 (1..5)) IS  -- ERROR: F3.
     BEGIN
          PARM1 := NEW ARR(1..5);
          PARM2 := NEW REC(5);
          PARM3 := NEW SUB_ARR;
     END PROC1;

     FUNCTION FUNC1 RETURN ARR_NAME (1..5) IS          -- ERROR: G1.
          F1 : ARR_NAME;
     BEGIN
          F1 := NEW ARR(1..5);
          RETURN F1;
     END FUNC1;

     FUNCTION FUNC2 RETURN REC_NAME (5) IS             -- ERROR: G2.
          F2 : REC_NAME;
     BEGIN
          F2 := NEW REC(5);
          RETURN F2;
     END FUNC2;

     FUNCTION FUNC3 RETURN ARR_NAME3 (1..5) IS         -- ERROR: G3.
          F3 : ARR_NAME3;
     BEGIN
          F3 := NEW SUB_ARR;
          RETURN F3;
     END FUNC3;

 BEGIN
     NULL;
END B38003C;
