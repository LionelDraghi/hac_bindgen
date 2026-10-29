--
-- ARM 5.5(18-26) Loop Statements
--
-- Success: 32:1..61:12 Tree *
--
-- package body ARM_5_5 is
-- begin
--    loop
--       Get (Current_Character);
--       exit when (Current_Character = '*');
--    end loop;
--    while (Bid (N).Price < Cut_Off.Price) loop
--       Record_Bid (Bid (N).Price);
--       N := (N + 1);
--    end loop;
--    for J in Buffer'Range loop
--       if (Buffer (J) /= Space) then
--          Put (Buffer (J));
--       end if;
--    end loop;
-- Summation :
--    while (Next /= Head) loop
--       Sum  := (Sum + Next.Value);
--       Next := Next.Succ;
--    end loop Summation;
--    parallel
--    for I in Grid'Range (1) loop
--       Grid (I, 1) := (for all J in Grid'Range (2) => (Grid (I, J) = True));
--    end loop;
-- end ARM_5_5;
--
package body ARM_5_5 is
begin
   loop
      Get(Current_Character);
      exit when Current_Character = '*';
   end loop;

   while Bid(N).Price < Cut_Off.Price loop
      Record_Bid(Bid(N).Price);
      N := N + 1;
   end loop;

   for J in Buffer'Range loop     --  works even with a null range
      if Buffer(J) /= Space then
         Put(Buffer(J));
      end if;
   end loop;

Summation :
   while Next /= Head loop       -- see 3.10.1
      Sum  := Sum + Next.Value;
      Next := Next.Succ;
   end loop Summation;

   -- see 3.6
   parallel
   for I in Grid'Range(1) loop
      Grid(I, 1) := (for all J in Grid'Range(2) => Grid(I,J) = True);
   end loop;
end ARM_5_5;