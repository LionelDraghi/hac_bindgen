--
-- ACATS B67001B
--
-- Failure: Invalid operator symbol 'IN' at 20:30..33
--
PROCEDURE B67001B IS
     PACKAGE P IS
          TYPE LIM_PRIV IS LIMITED PRIVATE;
     PRIVATE
          TYPE LIM_PRIV IS NEW INTEGER;
     END P;
     USE P;
BEGIN

     --------------------------------------------------

     DECLARE -- (A)
          GENERIC

               WITH FUNCTION "IN" (I1, I2, I3 : INTEGER)   -- ERROR: IN
                    RETURN BOOLEAN;

               WITH FUNCTION "NOT IN"                      -- ERROR:
                    (I1, I2, I3 : INTEGER) RETURN BOOLEAN; -- NOT IN.

               WITH FUNCTION "AND THEN" (B1, B2 : BOOLEAN) -- ERROR:
                    RETURN BOOLEAN;                        -- AND THEN.

               WITH FUNCTION "OR ELSE" (B1, B2 : BOOLEAN)  -- ERROR:
                    RETURN BOOLEAN;                        -- OR ELSE.

               WITH FUNCTION "/=" (I1, I2: LIM_PRIV)       -- ERROR: /=
                    RETURN BOOLEAN;

          PACKAGE PKG IS
          END PKG;

     BEGIN -- (A)
          NULL;
     END; -- (A)

     --------------------------------------------------

     DECLARE -- (B)
          GENERIC

               WITH FUNCTION "AND" (B1 : BOOLEAN)          -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "OR" (B1 : BOOLEAN)           -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "XOR" (B1 : BOOLEAN)          -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "=" (B1 : LIM_PRIV)           -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "<=" (B1 : BOOLEAN)           -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "<" (B1 : BOOLEAN)            -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION ">=" (B1 : BOOLEAN)           -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION ">" (B1 : BOOLEAN)            -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "&" (B1 : BOOLEAN)            -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "*" (B1 : BOOLEAN)            -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "/" (B1 : BOOLEAN)            -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "MOD" (B1 : BOOLEAN)          -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "REM" (B1 : BOOLEAN)          -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "**" (B1 : BOOLEAN)           -- ERROR: TOO
                                                           -- FEW ARGS.
                    RETURN BOOLEAN;

          PACKAGE PKG1 IS
          END PKG1;

     BEGIN -- (B)
          NULL;
     END; -- (B)

     --------------------------------------------------

     DECLARE -- (C)
          GENERIC

               WITH FUNCTION "AND" (B1, B2, B3 : BOOLEAN)  -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "OR" (B1, B2, B3: BOOLEAN)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "XOR" (B1, B2, B3 : BOOLEAN)  -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "=" (B1, B2, B3 : LIM_PRIV)   -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "<=" (B1, B2, B3 : BOOLEAN)   -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "<" (B1, B2, B3 : BOOLEAN)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION ">=" (B1, B2, B3 : BOOLEAN)   -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION ">" (B1, B2, B3 : BOOLEAN)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "&" (B1, B2, B3 : BOOLEAN)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "*" (B1, B2, B3 : BOOLEAN)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "/" (B1, B2, B3 : BOOLEAN)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "MOD" (B1, B2, B3 : BOOLEAN)  -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "REM" (B1, B2, B3 : BOOLEAN)  -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "**" (B1, B2, B3 : BOOLEAN)   -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

          PACKAGE PKG2 IS
          END PKG2;

     BEGIN -- (C)
          NULL;
     END; -- (C)

     ---------------------------------------------------

     DECLARE -- (D)

          GENERIC

               WITH FUNCTION "NOT" (B1, B2 : BOOLEAN)      -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN BOOLEAN;

               WITH FUNCTION "ABS" (I1, I2 : INTEGER)      -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN INTEGER;

          PACKAGE PKG4 IS
          END PKG4;

     BEGIN -- (D)
          NULL;
     END; -- (D)

     --------------------------------------------------

     DECLARE -- (E)

          GENERIC

               WITH FUNCTION "+" RETURN INTEGER;           -- ERROR: TOO
                                                           -- FEW ARGS.

               WITH FUNCTION "-" RETURN INTEGER;           -- ERROR: TOO
                                                           -- FEW ARGS.

               WITH FUNCTION "NOT" RETURN BOOLEAN;         -- ERROR: TOO
                                                           -- FEW ARGS.

               WITH FUNCTION "ABS" RETURN INTEGER;         -- ERROR: TOO
                                                           -- FEW ARGS.

          PACKAGE PKG5 IS
          END PKG5;

     BEGIN -- (E)
          NULL;
     END; -- (E)

     --------------------------------------------------

     DECLARE -- (F)

          GENERIC

               WITH FUNCTION "+" (I1, I2, I3 : INTEGER)    -- ERROR: TOO
                                                           -- MANY ARGS.
                    RETURN INTEGER;

               WITH FUNCTION "-" (I1, I2, I3 : INTEGER)    -- ERROR: TOO
                                                           -- MANY ARGS.
                     RETURN INTEGER;

          PACKAGE PKG6 IS
          END PKG6;

     BEGIN -- (F)
          NULL;
     END; -- (F)

     --------------------------------------------------

     DECLARE -- (G)

          GENERIC

               WITH FUNCTION "+" (I1, I2: INTEGER := 0)      -- ERROR:
                    RETURN INTEGER;                          -- DEFAULT.

          PACKAGE PKG7 IS
          END PKG7;

     BEGIN -- (G)
          NULL;
     END; -- (G)

     --------------------------------------------------

     DECLARE -- (H)

          GENERIC

               WITH FUNCTION " +" (I1, I2: INTEGER)      -- ERROR:
                    RETURN INTEGER;                      -- LEADING BLK.

               WITH FUNCTION "+ " (I1, I2: INTEGER)      -- ERROR:
                    RETURN INTEGER;                      -- TRAILG BLK.

               WITH FUNCTION "NOT " (B1, B2: BOOLEAN)    -- ERROR:
                    RETURN BOOLEAN;                      -- TRAILG BLK.

               WITH FUNCTION " NOT" (B1, B2: BOOLEAN)    -- ERROR:
                    RETURN BOOLEAN;                      -- LEADING BLK.

          PACKAGE PKG8 IS
          END PKG8;

     BEGIN -- (H)
          NULL;
     END; -- (H)

END B67001B;
