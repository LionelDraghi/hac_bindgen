--
-- ACATS B71001P
--
-- Failure: Function body stub is not allowed in package declarative items context as found at 11:35..42
--
PACKAGE B71001P IS

     GENERIC 
     FUNCTION F RETURN INTEGER;

     FUNCTION F RETURN INTEGER IS SEPARATE;     -- ERROR: STUB.

END B71001P;
