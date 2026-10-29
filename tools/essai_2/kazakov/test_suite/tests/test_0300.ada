--
-- ACATS B56001H
--
-- Failure: Semicolon is expected at 16:10
--
PROCEDURE B56001H IS
BEGIN

 L3: DECLARE
     BEGIN
          DECLARE
          BEGIN
               NULL;
          EXCEPTION
               WHEN OTHERS => NULL;
     END L3;                            -- ERROR: MISSING END.

END B56001H;
