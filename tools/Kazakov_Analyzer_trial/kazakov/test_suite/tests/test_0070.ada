--
-- ARM 5.8 Goto Statements
--
-- Success: 17:1..26:12 Tree *
--
-- package body ARM_5_8 is
-- begin
--    <<Sort>>
--    for I in 1..(N - 1) loop
--       if (A (I) > A ((I + 1))) then
--          Exchange (A (I), A ((I + 1)));
--          goto Sort;
--       end if;
--    end loop;
-- end ARM_5_8;
--
package body ARM_5_8 is
begin
   <<Sort>>
   for I in 1 .. N-1 loop
      if A(I) > A(I+1) then
         Exchange(A(I), A(I+1));
         goto Sort;
      end if;
   end loop;
end ARM_5_8;