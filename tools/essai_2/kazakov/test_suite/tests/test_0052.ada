--
-- ARM 4.5.10(50-52) Reduction Expressions
--
-- Success: 24:1..41:15
--
-- package ARM_4_5_10 is
--    type Accumulator is record
--       Sum   : Real;
--       Count : Integer;
--    end record;
-- 
--    function Accumulate (L, R : Accumulator) return Accumulator is
--      ((Sum   => (L.Sum   + R.Sum),
--       Count => (L.Count + R.Count)));
--
--    function Average_of_Values_Greater_Than_100 (M : Matrix) return Real is
--       ((declare
--           Acc : constant Accumulator :=
--              [parallel for Val of M when (Val > 100.0) => (Val, 1)]'Reduce (Accumulate, (Sum => 0, Count => 0));
--        begin
--           (Acc.Sum / Real (Acc.Count))));
-- end ARM_4_5_10;
--
package ARM_4_5_10 is
   type Accumulator is record
      Sum   : Real; -- See 3.5.7.
      Count : Integer;
   end record;

   function Accumulate (L, R : Accumulator) return Accumulator is
     (Sum   => L.Sum   + R.Sum,
      Count => L.Count + R.Count);

   function Average_of_Values_Greater_Than_100 (M : Matrix) return Real is
      (declare
          Acc : constant Accumulator :=
             [parallel for Val of M when Val > 100.0 => (Val, 1)]
               'Reduce(Accumulate, (Sum => 0, Count => 0));
       begin
          Acc.Sum / Real(Acc.Count));
end ARM_4_5_10;