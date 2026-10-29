--
-- ACATS B71001J
--
-- Failure: Procedure body stub is not allowed in package declarative items context as found at 9:22..29
--
GENERIC
PACKAGE B71001J IS

     PROCEDURE PR IS SEPARATE;          -- ERROR: STUB.

END B71001J;
