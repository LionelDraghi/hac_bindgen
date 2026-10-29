--
-- ACATS B91001E
--
-- Failure: 'task' is unexpected inside a library unit context as found at 6:1..4
--
TASK TYPE B91001E IS                -- ERROR: LIBRARY TASK PROHIBITED.
     ENTRY E;
END B91001E;