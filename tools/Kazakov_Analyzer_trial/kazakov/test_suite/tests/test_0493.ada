--
-- ACATS BA2001D
--
-- Failure: Function stubs are not allowed for operators as found at 8:15..17
--
PROCEDURE BA2001D IS

     FUNCTION "*" (X, Y : INTEGER) RETURN INTEGER IS SEPARATE; -- ERROR:
                                        -- ILLEGAL NAME FOR BODY_STUB.

BEGIN
     NULL;
END BA2001D;
