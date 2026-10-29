--
-- ARM 13.5.1 Record Representation Clauses
--
-- Success: 39:1..75:15 Tree *
--
-- package ARM_13_5_1 is
--    Word : constant := 4;
--    type State         is (A, M, W, P);
--    type Mode          is (Fix, Dec, Exp, Signif);
--    type Byte_Mask     is array (0..7)  of Boolean with Component_Size => 1;
--    type State_Mask    is array (State) of Boolean with Component_Size => 1;
--    type Mode_Mask     is array (Mode)  of Boolean with Component_Size => 1;
--    type Program_Status_Word is
--      record
--          System_Mask        : Byte_Mask;
--          Protection_Key     : Integer range 0..3;
--          Machine_State      : State_Mask;
--          Interrupt_Cause    : Interruption_Code;
--          Ilc                : Integer range 0..3;
--          Cc                 : Integer range 0..3;
--          Program_Mask       : Mode_Mask;
--          Inst_Address       : Address;
--    end record;
--    for Program_Status_Word use
--      record
--          System_Mask      at (0 * Word) range 0..7;
--          Protection_Key   at (0 * Word) range 10..11;
--          Machine_State    at (0 * Word) range 12..15;
--          Interrupt_Cause  at (0 * Word) range 16..31;
--          Ilc              at (1 * Word) range 0..1;
--          Cc               at (1 * Word) range 2..3;
--          Program_Mask     at (1 * Word) range 4..7;
--          Inst_Address     at (1 * Word) range 8..31;
--      end record;
--    for Program_Status_Word'Size use (8 * System.Storage_Unit);
--    for Program_Status_Word'Alignment use 8;
-- end ARM_13_5_1;
--
package ARM_13_5_1 is
   Word : constant := 4;  --  storage element is byte, 4 bytes per word

   type State         is (A,M,W,P);
   type Mode          is (Fix, Dec, Exp, Signif);

   type Byte_Mask     is array (0..7)  of Boolean with Component_Size => 1;
   type State_Mask    is array (State) of Boolean with Component_Size => 1;
   type Mode_Mask     is array (Mode)  of Boolean with Component_Size => 1;

   type Program_Status_Word is
     record
         System_Mask        : Byte_Mask;
         Protection_Key     : Integer range 0 .. 3;
         Machine_State      : State_Mask;
         Interrupt_Cause    : Interruption_Code;
         Ilc                : Integer range 0 .. 3;
         Cc                 : Integer range 0 .. 3;
         Program_Mask       : Mode_Mask;
         Inst_Address       : Address;
   end record;

   for Program_Status_Word use
     record
         System_Mask      at 0*Word range 0  .. 7;
         Protection_Key   at 0*Word range 10 .. 11; -- bits 8,9 unused
         Machine_State    at 0*Word range 12 .. 15;
         Interrupt_Cause  at 0*Word range 16 .. 31;
         Ilc              at 1*Word range 0  .. 1;  -- second word
         Cc               at 1*Word range 2  .. 3;
         Program_Mask     at 1*Word range 4  .. 7;
         Inst_Address     at 1*Word range 8  .. 31;
     end record;

   for Program_Status_Word'Size use 8*System.Storage_Unit;
   for Program_Status_Word'Alignment use 8;
end ARM_13_5_1;