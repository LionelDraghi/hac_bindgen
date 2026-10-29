--
-- ARM 8.5.2 Exception Renaming Declarations
--
-- Success: 10:1..14:14 Tree *
--
-- package ARM_8_5_2 is
--    EOF : exception renames Ada.IO_Exceptions.End_Error;
-- end ARM_8_5_2;
--
package ARM_8_5_2 is

   EOF : exception renames Ada.IO_Exceptions.End_Error; -- see A.13

end ARM_8_5_2;