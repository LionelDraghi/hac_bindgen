--
-- ACATS BA1001A4
--
-- Failure: An identifier is expected at 7:10..12
--
WITH BA1001A0M_PKG; USE BA1001A0M_PKG;
FUNCTION "=" (LEFT, RIGHT: LIM) RETURN BOOLEAN IS            -- ERROR:
                                                   -- OPERATOR SYMBOL.
BEGIN
     RETURN FALSE;
END "=";
