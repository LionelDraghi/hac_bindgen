--
-- ARM 4.8(10) Allocators
--
-- Success: 17:1..30:12 Tree *
--
-- package body ARM_4_8 is
--    task body TT is
--       type Acc_TC is access T'Class;
--       P : Acc_TC;
--    begin
--       accept E (X : T'Class) do
--          P := new (T'Class'(X));
--       end E;
--    end TT;
-- end ARM_4_8;
--
package body ARM_4_8 is
   task body TT is
      type Acc_TC is access T'Class;
      P : Acc_TC;
   begin
      accept E(X : T'Class) do
         P := new T'Class'(X);
            --  Master check on tag of X.
            --  Can't use "accessibility levels" since they might be incomparable.
            --  Must revert to checking that the master of the type identified by
            --  X'tag includes the elaboration of Acc_TC, so it is sure to outlive it.
      end E;
   end TT;
end ARM_4_8;