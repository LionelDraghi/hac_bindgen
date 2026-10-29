--
-- ARM 3.9(31) Tagged Types and Type Extensions
--
-- Success: 21:1..29:45 Tree *
--
-- with Ada.Text_IO;
-- generic
--    Z : in out Integer;
-- package ARM_3_9.Tagged_Types_and_Type_Extensions is
--    type Point is tagged
--      record
--        X, Y : Real := 0.0;
--      end record;
-- 
--    type Expression is tagged null record;
-- end ARM_3_9.Tagged_Types_and_Type_Extensions;
--
with Ada.Text_IO;
generic
   Z : in out Integer;
package ARM_3_9.Tagged_Types_and_Type_Extensions is
   type Point is tagged
     record
       X, Y : Real := 0.0;
     end record;

   type Expression is tagged null record;
     -- Components will be added by each extension
end ARM_3_9.Tagged_Types_and_Type_Extensions;