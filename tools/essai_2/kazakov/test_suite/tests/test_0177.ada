--
-- ACATS B26002A.ADA
--
-- Failure: Missing " closing the string literal at 12:15..58
--
PROCEDURE B26002A  IS

        C1 : STRING(1..1);
        C3 : STRING(1..5);

BEGIN
        C1 := """;      -- ERROR: QUOTE MUST BE DOUBLED IN
                        --        STRING LITERALS.
        NULL;

        C3 := "ABCD"";  -- ERROR: QUOTE MUST BE DOUBLED IN
                        --        STRING LITERALS.
        NULL;

        C3 := ""BCDE";  -- ERROR: QUOTE MUST BE DOUBLED IN
                        --        STRING LITERALS.
        NULL;

        C3 := "AB"DE";  -- ERROR: QUOTE MUST BE DOUBLED IN
                        --        STRING LITERALS.
        NULL;

END B26002A;