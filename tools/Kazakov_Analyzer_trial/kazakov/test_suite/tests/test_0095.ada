--
-- ARM 8.5.1(8) Object Renaming Declarations
--
-- Success: 20:1..37:14 Tree *
--
-- package body ARM_8_5_1 is
--    type Acc_I is access Integer;
--    subtype Acc_NN_I is not null Acc_I;
--    Obj : Acc_I := null;
--    generic
--       B : in out Acc_NN_I;
--    package Gen is
--    end Gen;
--    package body Gen is
--       D : not null Acc_I renames B;
--    end Gen;
--    package Inst is new Gen (B => Obj);
-- end ARM_8_5_1;
--
package body ARM_8_5_1 is

   type Acc_I is access Integer;
   subtype Acc_NN_I is not null Acc_I;
   Obj : Acc_I := null;

   generic
      B : in out Acc_NN_I;
   package Gen is
   end Gen;

   package body Gen is
      D : not null Acc_I renames B;
   end Gen;

   package Inst is new Gen (B => Obj);

end ARM_8_5_1;