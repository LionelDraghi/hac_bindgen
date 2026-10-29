--
-- ACATS B91002I
--
-- Failure: 'package' is unexpected inside a task public items context as found at 12:11..17
--
PROCEDURE B91002I IS

     TASK TYPE T2I IS

          ENTRY E;

          PACKAGE PKG IS             -- ERROR: PROHIBITED IN TASK SPEC.
               I : INTEGER;
          END PKG;

     END T2I;

     TASK BODY T2I IS
     BEGIN
          NULL;
     END;

BEGIN
     NULL;
END B91002I;