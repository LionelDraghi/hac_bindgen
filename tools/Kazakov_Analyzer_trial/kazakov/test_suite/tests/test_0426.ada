--
-- ACATS B71001V
--
-- Failure: Function body stub is not allowed in package declarative items context as found at 12:36..43
--
GENERIC
PACKAGE B71001V IS

     GENERIC
     FUNCTION FR RETURN INTEGER;

     FUNCTION FR RETURN INTEGER IS SEPARATE;      -- ERROR: STUB.

END B71001V;

