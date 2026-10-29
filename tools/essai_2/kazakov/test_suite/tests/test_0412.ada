--
-- ACATS B71001D
--
-- Failure: Procedure body stub is not allowed in package declarative items context as found at 8:22..29
--
PACKAGE B71001D IS

     PROCEDURE PR IS SEPARATE;          -- ERROR: STUB.

END B71001D;
