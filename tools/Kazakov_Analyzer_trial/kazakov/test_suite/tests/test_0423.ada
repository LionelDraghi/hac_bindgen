--
-- ACATS B71001R
--
-- Failure: Task body stub is not allowed in package declarative items context as found at 9:21..28
--
PACKAGE B71001R IS

     TASK T;
     TASK BODY T IS SEPARATE;         -- ERROR: BODY.

END B71001R;
