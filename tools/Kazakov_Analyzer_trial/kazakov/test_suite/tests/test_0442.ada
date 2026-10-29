--
-- ACATS B91001F
--
-- Failure: 'T2' at 12:11..12 is not matched by 'TS2' at 14:10..12
--
PROCEDURE B91001F IS

--   TASK TYPE T1 IS
--        ENTRY E;
--   END TS1;                      -- ERROR: NON-MATCHING IDENTIFIER.

     TASK T2 IS
          ENTRY E;
     END TS2;                      -- ERROR: NON-MATCHING IDENTIFIER.

     TASK BODY T1 IS
     BEGIN
          NULL;
     END TB1;                      -- ERROR: NON-MATCHING IDENTIFIER.

     TASK BODY T2 IS
     BEGIN
          NULL;
     END T1;                       -- ERROR: NON-MATCHING IDENTIFIER.

BEGIN
     NULL;
END B91001F;
