--
-- ARM 7.4 Deferred Constants
--
-- Success: 12:1..19:12 Tree *
--
-- package ARM_7_4 is
--    Null_Key : constant Key;
--    CPU_Identifier : constant String (1..8)
--       with Import => True, Convention => Assembler, Link_Name => "CPU_ID";
-- end ARM_7_4;
--
package ARM_7_4 is

   Null_Key : constant Key;      -- see 7.3.1

   CPU_Identifier : constant String(1..8)
      with Import => True, Convention => Assembler, Link_Name => "CPU_ID";

end ARM_7_4;