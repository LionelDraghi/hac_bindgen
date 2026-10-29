--
-- ACATS B71001G
--
-- Failure: 'P3' at 10:19..20 is not matched by 'P2' at 11:15..16
--
PROCEDURE B71001G IS

     GENERIC
     PACKAGE  P2 IS
          PACKAGE P3 IS
          END P2;                            -- ERROR: P2.
     END P4;                                 -- ERROR: P4.

     GENERIC
     PACKAGE P5 IS
          PACKAGE P6 IS
          END P6;
     END P5;

     PACKAGE BODY P5 IS
          PACKAGE BODY P6 IS
          END P5;                            -- ERROR: P5.
     END P6;                                 -- ERROR: P6.

BEGIN
     NULL;
END B71001G;
