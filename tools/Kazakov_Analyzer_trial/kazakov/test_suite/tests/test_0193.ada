--
-- ACATS B33101A.ADA
--
-- Failure: Array type is not alloved to have discriminants as found at 15:13..19
--
PROCEDURE B33101A IS

     SUBTYPE S IS INTEGER RANGE 0..10;

--   TYPE E (D : S) IS (E1, E2);        -- ERROR: DISCRIMINANT_PART.   {6}
--   TYPE I (D : S) IS RANGE 0..10;     -- ERROR: DISCRIMINANT_PART.   {6}
--   TYPE R (D : S) IS DIGITS 3;        -- ERROR: DISCRIMINANT_PART.   {6}
--   TYPE F (D : S) IS DELTA 1.0
--                     RANGE 0.0 .. 3.0;-- ERROR: DISCRIMINANT_PART. {1:6}
     TYPE A (D : S) IS ARRAY (S) OF S;  -- ERROR: DISCRIMINANT_PART.   {6}
     TYPE P (D : S) IS ACCESS S;        -- ERROR: DISCRIMINANT_PART.   {6}
     TYPE N (D : S) IS NEW INTEGER;     -- ERROR: DISCRIMINANT_PART.   {6}

BEGIN
     NULL;
END B33101A;
