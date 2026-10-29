--
-- ARM 7.3 Private Types and Private Extensions
--
-- Success: 12:1..19:12 Tree *
--
-- package ARM_7_3 is
--    type Key is private;
--    type File_Name is limited private;
--    type List is new Ada.Finalization.Controlled with private;
-- end ARM_7_3;
--
package ARM_7_3 is

   type Key is private;
   type File_Name is limited private;

   type List is new Ada.Finalization.Controlled with private;

end ARM_7_3;