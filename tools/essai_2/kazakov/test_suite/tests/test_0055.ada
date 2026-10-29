--
-- ARM 5.1 Simple and Compound Statements - Sequences of Statements
--
-- Success: 34:1..62:12 Tree *
--
-- package body ARM_5_1 is
--    task body Compute is
--       Sum : Integer := 0;
--    begin
--     Outer :
--       for I in 1..10 loop
--        Blk :
--          declare
--             Sum : Integer := 0;
--          begin
--             accept Ent (I : out Integer; J : Integer) do
--                Compute.Ent.I := Compute.Outer.I;
--              Inner :
--                for J in 1..10 loop
--                   Sum := (Sum + (Compute.Blk.Inner.J * Compute.Ent.J));
--                end loop Inner;
--             end Ent;
--             Compute.Sum := (Compute.Sum + Compute.Blk.Sum);
--          end Blk;
--       end loop Outer;
--       Record_Result (Sum);
--    end Compute;
-- begin
--    <<Here>> <<Ici>> <<Aqui>> <<Hier>> null;
--    <<After>> X := 1;
--    <<Last>>
-- end ARM_5_1;
--
package body ARM_5_1 is
   task body Compute is
      Sum : Integer := 0;                       -- Compute.Sum
   begin
    Outer:                                      -- Compute.Outer
      for I in 1..10 loop     -- Compute.Outer.I
       Blk:                                     -- Compute.Blk
         declare
            Sum : Integer := 0;                 -- Compute.Blk.Sum
         begin
            accept Ent(I : out Integer; J : in Integer) do
                                                -- Compute.Ent.I, Compute.Ent.J
               Compute.Ent.I := Compute.Outer.I;
             Inner:                             -- Compute.Blk.Inner
               for J in 1..10 loop
                                                -- Compute.Blk.Inner.J
                  Sum := Sum + Compute.Blk.Inner.J * Compute.Ent.J;
               end loop Inner;
            end Ent;
            Compute.Sum := Compute.Sum + Compute.Blk.Sum;
         end Blk;
      end loop Outer;
      Record_Result(Sum);
   end Compute;
begin
   <<Here>> <<Ici>> <<Aqui>> <<Hier>> null;
   <<After>> X := 1;
   <<Last>>
end ARM_5_1;