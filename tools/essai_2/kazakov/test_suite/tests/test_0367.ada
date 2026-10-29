--
-- ACATS B67001C
--
-- Failure: Invalid operator symbol 'IN' at 79:20..23
--
PROCEDURE B67001C IS

     GENERIC
          TYPE ELEMENT IS (<>);
     FUNCTION NO_PARAMS RETURN BOOLEAN;
     FUNCTION NO_PARAMS RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END NO_PARAMS;

     GENERIC
          TYPE ELEMENT IS (<>);
     FUNCTION ONE_PARAM (P1 : ELEMENT) RETURN BOOLEAN;
     FUNCTION ONE_PARAM (P1 : ELEMENT) RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END ONE_PARAM;

     GENERIC
          TYPE ELEMENT IS (<>);
     FUNCTION TWO_PARAMS (P1, P2 : ELEMENT) RETURN BOOLEAN;
     FUNCTION TWO_PARAMS (P1, P2 : ELEMENT) RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END TWO_PARAMS;

     GENERIC
          TYPE ELEMENT IS (<>);
     FUNCTION THREE_PARAMS (P1, P2, P3 : ELEMENT) RETURN BOOLEAN;
     FUNCTION THREE_PARAMS (P1, P2, P3 : ELEMENT) RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END THREE_PARAMS;

     GENERIC
          TYPE ELEMENT IS LIMITED PRIVATE;
     FUNCTION LP_ONE_PARAM (P1 : ELEMENT) RETURN BOOLEAN;
     FUNCTION LP_ONE_PARAM (P1 : ELEMENT) RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END LP_ONE_PARAM;

     GENERIC
          TYPE ELEMENT IS LIMITED PRIVATE;
     FUNCTION LP_THREE_PARAMS (P1, P2, P3 : ELEMENT) RETURN BOOLEAN;
     FUNCTION LP_THREE_PARAMS (P1, P2, P3 : ELEMENT) RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END LP_THREE_PARAMS;

     PACKAGE PKG IS
          TYPE LP IS LIMITED PRIVATE;
     PRIVATE
          TYPE LP IS NEW INTEGER;
     END PKG;

     GENERIC
          TYPE ELEMENT IS (<>);
          IDN : ELEMENT;
     FUNCTION T_PARAMS (P1 : ELEMENT; P2 : ELEMENT := IDN)
          RETURN BOOLEAN;
     FUNCTION T_PARAMS (P1 : ELEMENT; P2 : ELEMENT := IDN)
          RETURN BOOLEAN IS
     BEGIN
          RETURN TRUE;
     END T_PARAMS;

BEGIN

     --------------------------------------------------

     DECLARE   -- (A)

          FUNCTION "IN" IS NEW THREE_PARAMS       -- ERROR: IN. {11}
               (ELEMENT => INTEGER);

          FUNCTION "NOT IN" IS NEW THREE_PARAMS   -- ERROR: NOT IN. {11}
               (ELEMENT => INTEGER);

          FUNCTION "AND THEN" IS NEW TWO_PARAMS   -- ERROR: AND THEN. {11}
               (ELEMENT => BOOLEAN);

          FUNCTION "OR ELSE" IS NEW TWO_PARAMS    -- ERROR: OR ELSE. {11}
               (ELEMENT => BOOLEAN);

          FUNCTION "/=" IS NEW TWO_PARAMS         -- ERROR: /=. {11}
               (ELEMENT => INTEGER);

     BEGIN     -- (A)
          NULL;
     END; -- (A)

     --------------------------------------------------

     DECLARE   -- (B)

          FUNCTION "AND" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "OR" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "XOR" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "=" IS NEW LP_ONE_PARAM
               (ELEMENT => PKG.LP);         -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "<=" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "<" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION ">=" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION ">" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "&" IS NEW ONE_PARAM
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "*" IS NEW ONE_PARAM
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "/" IS NEW ONE_PARAM
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "MOD" IS NEW ONE_PARAM
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "REM" IS NEW ONE_PARAM
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "**" IS NEW ONE_PARAM
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

     BEGIN     -- (B)
          NULL;
     END; -- (B)

     --------------------------------------------------

     DECLARE   -- (C)

          FUNCTION "AND" IS NEW THREE_PARAMS
               (ELEMENT => BOOLEAN);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "OR" IS NEW THREE_PARAMS
               (ELEMENT => BOOLEAN);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "XOR" IS NEW THREE_PARAMS
               (ELEMENT => BOOLEAN);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "=" IS NEW LP_THREE_PARAMS
               (ELEMENT => PKG.LP);         -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "<=" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "<" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION ">=" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION ">" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "&" IS NEW THREE_PARAMS
               (ELEMENT => BOOLEAN);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "*" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "/" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "MOD" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "REM" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "**" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

     BEGIN     -- (C)
          NULL;
     END; -- (C)

     --------------------------------------------------

     DECLARE   -- (D)

          FUNCTION "NOT" IS NEW TWO_PARAMS
               (ELEMENT => BOOLEAN);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "ABS" IS NEW TWO_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

     BEGIN     -- (D)
          NULL;
     END; -- (D)

     --------------------------------------------------

     DECLARE   -- (E)

          FUNCTION "+" IS NEW NO_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "-" IS NEW NO_PARAMS 
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "NOT" IS NEW NO_PARAMS
               (ELEMENT => BOOLEAN);        -- ERROR: TOO FEW PARAMS. {1:11;1}

          FUNCTION "ABS" IS NEW NO_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO FEW PARAMS. {1:11;1}

     BEGIN     -- (E)
          NULL;
     END; -- (E)

     --------------------------------------------------

     DECLARE   -- (F)

          FUNCTION "+" IS NEW THREE_PARAMS
               (ELEMENT => INTEGER);        -- ERROR: TOO MANY PARAMS. {1:11;1}

          FUNCTION "-" IS NEW THREE_PARAMS  -- ERROR: TOO MANY PARAMS. {1:11;1}
               (ELEMENT => INTEGER);

     BEGIN     -- (F)
          NULL;
     END; -- (F)

     --------------------------------------------------

     DECLARE   -- (G)

          FUNCTION "+" IS NEW T_PARAMS
              (ELEMENT => INTEGER, IDN => 0); -- ERROR: DEFAULT VALUE. {1:11;1}

     BEGIN     -- (G)
          NULL;
     END; -- (G)

     --------------------------------------------------

     DECLARE   -- (H)

          FUNCTION " +" IS NEW TWO_PARAMS    -- ERROR: LEADING BLANK. {11}
               (ELEMENT => INTEGER);

          FUNCTION "+ " IS NEW TWO_PARAMS    -- ERROR: TRAILING BLANK. {11}
               (ELEMENT => INTEGER);

          FUNCTION "NOT " IS NEW TWO_PARAMS  -- ERROR: TRAILING BLANK. {11}
               (ELEMENT => BOOLEAN);

          FUNCTION " NOT" IS NEW TWO_PARAMS  -- ERROR: LEADING BLANK. {11}
               (ELEMENT => BOOLEAN);

     BEGIN     -- (H)
          NULL;
     END; -- (H)

     --------------------------------------------------

END B67001C;