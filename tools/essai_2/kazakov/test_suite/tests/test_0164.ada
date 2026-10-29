--
-- ACATS B2A021A.ADA
--
-- Failure: Expression is expected at 7:27
--
PROCEDURE B2A021A IS
     X : STRING (1..5) := %12"45%;      -- ERROR: " NOT ALLOWED.
     B : BOOLEAN;
BEGIN
     B := %AB% = %""%;                  -- ERROR: " NOT ALLOWED.
END B2A021A;
