--
-- ARM 3.6.1 Index Constraints and Discrete Ranges
--
-- Success: 19:1..35:52 Tree *
--
-- package ARM_3_6_1.Index_Constraints_And_Discrete_Ranges is
--    Board     : Matrix (1..8,  1..8);
--    Rectangle : Matrix (1..20, 1..30);
--    Inverse   : Matrix (1..N,  1..N);
--    Filter    : Bit_Vector (0..31);
--    My_Schedule : Schedule;
--    type Var_Line (Length : Natural) is
--       record
--          Image : String (1..Length);
--       end record;
--    Null_Line : Var_Line (0);
-- end ARM_3_6_1.Index_Constraints_And_Discrete_Ranges;
--
package ARM_3_6_1.Index_Constraints_And_Discrete_Ranges is
   Board     : Matrix(1 .. 8,  1 .. 8);  -- see 3.6
   Rectangle : Matrix(1 .. 20, 1 .. 30);
   Inverse   : Matrix(1 .. N,  1 .. N);  -- N can be nonstatic need not be static

   Filter    : Bit_Vector(0 .. 31);      -- see 3.6

   My_Schedule : Schedule;  -- all arrays of type Schedule have the same bounds

   type Var_Line(Length : Natural) is
      record
         Image : String(1 .. Length);
      end record;

   Null_Line : Var_Line(0);  -- Null_Line.Image is a null array

end ARM_3_6_1.Index_Constraints_And_Discrete_Ranges;