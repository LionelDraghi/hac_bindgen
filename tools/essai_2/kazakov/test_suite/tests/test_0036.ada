--
-- ARM 3.9_4(35) Interface Types
--
-- Success: 12:1..16:14 Tree *
--
-- package ARM_3_9_4 is
--    type Serial_Device is task interface;
--    procedure Read (Dev : Serial_Device; C : out Character) is abstract;
--    procedure Write (Dev : Serial_Device; C : Character) is abstract;
-- end ARM_3_9_4;
--
package ARM_3_9_4 is
   type Serial_Device is task interface;  -- see 9.1
   procedure Read (Dev : in Serial_Device; C : out Character) is abstract;
   procedure Write(Dev : in Serial_Device; C : in  Character) is abstract;
end ARM_3_9_4;