--
-- ARM 3.3.1(20) Subtype Predicates
--
-- Success: 21:1..33:34 Tree *
--
-- with Ada.IO_Exceptions;
-- package body ARM_3_3_1.Object_Declarations is
--    type R (D : Integer := F) is record
--       S : String (1..D) := (others => G);
--    end record;
--    X : R;
--    type T (D : Natural) is
--      limited record
--         C1 : T1 (T'Access);
--         C2 : Natural := F (D);
--         C3 : String (1..D) := (others => ' ');
--      end record;
-- end ARM_3_3_1.Object_Declarations;
--
with Ada.IO_Exceptions;
package body ARM_3_3_1.Object_Declarations is
   type R(D : Integer := F) is
      record
         S : String(1..D) := (others => G);
      end record;
   X : R;
   type T (D : Natural) is
      limited record
         C1 : T1 (T'Access);
         C2 : Natural := F (D);
         C3 : String (1 .. D) := (others => ' ');
      end record;
end ARM_3_3_1.Object_Declarations;