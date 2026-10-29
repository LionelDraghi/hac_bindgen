--
-- ACATS B56001A
--
-- Failure: 'L1' at 24:6..7 is not matched by 'L2' at 27:15..16
--
PROCEDURE B56001A IS
BEGIN

--     B1 : BEGIN
--          NULL;
--     END;                                    -- ERROR: MISSING B1.  {2:6;1}

--     B2 : BEGIN
--          NULL;
--     END B1;                                 -- ERROR: B1 NOT B2.   {2:6;1}

     B3 : DECLARE
     BEGIN
          NULL;
     EXCEPTION
          WHEN OTHERS => NULL;
     END B3;                                 -- OK.                 {5:6;1}

     L1 : DECLARE
          BEGIN
               NULL;
          END L2;                            -- ERROR: L2.          {3:6;1}

     L3 : DECLARE
          BEGIN NULL;
          END;                               -- ERROR: MISSING ID.  {2:6;1}

END B56001A;
