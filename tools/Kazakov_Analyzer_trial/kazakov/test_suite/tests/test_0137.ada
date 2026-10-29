--
-- ARM 13.9 Unchecked Type Conversions
--
-- Success: 15:1..16:51 Tree *
--
-- generic
--    type Source (<>) is limited private;
--    type Target (<>) is limited private;
-- function Ada.Unchecked_Conversion (S : Source) return Target
--    with Pure, Nonblocking, Convention => Intrinsic;
--
generic
   type Source(<>) is limited private;
   type Target(<>) is limited private;
function Ada.Unchecked_Conversion(S : Source) return Target
   with Pure, Nonblocking, Convention => Intrinsic;