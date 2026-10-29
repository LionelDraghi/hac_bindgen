--
-- ACATS B91001F
--
-- Failure: 'T1' at 16:16..17 is not matched by 'TB1' at 19:10..12
--
PROCEDURE B91001F IS

--   TASK TYPE T1 IS
--        ENTRY E;
--   END TS1;                      -- ERROR: NON-MATCHING IDENTIFIER.

--   TASK T2 IS
--        ENTRY E;
--   END TS2;                      -- ERROR: NON-MATCHING IDENTIFIER.

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
