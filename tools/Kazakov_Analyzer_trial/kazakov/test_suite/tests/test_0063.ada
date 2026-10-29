--
-- ARM 5.5.2 Generalized Loop Iteration
--
-- Success: 13:1..18:14 Tree *
--
-- package body ARM_4_5_2 is
-- begin
--    for Element of Board loop
--       Element := (Element * 2.0);
--    end loop;
-- end ARM_4_5_2;
--
package body ARM_4_5_2 is
begin
   for Element of Board loop  -- See 3.6.1.
      Element := Element * 2.0; -- Double each element of Board, a two-dimensional array.
   end loop;
end ARM_4_5_2;