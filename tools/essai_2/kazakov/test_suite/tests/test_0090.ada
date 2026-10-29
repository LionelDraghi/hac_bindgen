--
-- ARM 8.3(26) Visibility
--
-- Success: 49:1..60:6, 62:1..66:6, 68:1..74:8, 77:1..81:6, 84:1..90:8 Tree *
--
-- package A is
--    type T is tagged private;
--    package B is
--       type NT is new T with record
--          I : Integer;
--       end record;
--    end B;
-- private
--    type T is tagged record
--       I : Integer;
--    end record;
-- end A;
-- 
-- package body A is
--    package body B is
-- 
--    end B;
-- end A;
-- 
-- package A.C is
--    type NT2 is new A.T with record
--       I : Integer;
--    end record;
-- private
-- 
-- end A.C;
-- 
-- with A;
-- package D is
--    type NT3 is new A.T with record
--       I : Integer;
--    end record;
-- end D;
-- 
-- with D;
-- package A.E is
--    type NT4 is new D.NT3 with null record;
--    X : NT4;
--    I1 : Integer := X.I;
--    I2 : Integer := D.NT3 (X).I;
--    I3 : Integer := A.T (X).I;
-- end A.E;
--
package A is
   type T is tagged private;
   package B is
      type NT is new T with record
         I: Integer; -- Illegal because T.I is visible in the body.
      end record; -- T.I is not visible here.
   end B;
private
   type T is tagged record
      I: Integer; -- Illegal because T.I is visible in the body.
   end record;
end A;

package body A is
   package body B is
      -- T.I becomes visible here.
   end B;
end A;

package A.C is
   type NT2 is new A.T with record
      I: Integer; -- Illegal because T.I is visible in the private part.
   end record; -- T.I is not visible here.
private
    -- T.I is visible here.
end A.C;

with A;
package D is
   type NT3 is new A.T with record
      I: Integer; -- Legal because T.I is never visible in this package.
   end record;
end D;

with D;
package A.E is
   type NT4 is new D.NT3 with null record;
   X : NT4;
   I1 : Integer := X.I;        -- D.NT3.I
   I2 : Integer := D.NT3(X).I; -- D.NT3.I
   I3 : Integer := A.T(X).I;   -- A.T.I
end A.E;