--
-- ARM 3.7 Discriminants
--
-- Success: 30:1..58:26 Tree *
--
-- package ARM_3_7.Discriminants is
--    type Buffer (Size : Buffer_Size := 100)  is
--       record
--          Pos   : Buffer_Size := 0;
--          Value : String (1..Size);
--       end record;
--    type Matrix_Rec (Rows, Columns : Integer) is
--       record
--          Mat : Matrix (1..Rows, 1..Columns);
--       end record;
--    type Square (Side : Integer) is new
--       Matrix_Rec (Rows => Side, Columns => Side);
--    type Double_Square (Number : Integer) is
--       record
--          Left  : Square (Number);
--          Right : Square (Number);
--       end record;
--    task type Worker (Prio : System.Priority; Buf : access Buffer)
--       with Priority => Prio is
--       entry Fill;
--       entry Drain;
--    end Worker;
-- end ARM_3_7.Discriminants;
--
package ARM_3_7.Discriminants is
   type Buffer(Size : Buffer_Size := 100)  is        -- see 3.5.4
      record
         Pos   : Buffer_Size := 0;
         Value : String(1 .. Size);
      end record;

   type Matrix_Rec(Rows, Columns : Integer) is
      record
         Mat : Matrix(1 .. Rows, 1 .. Columns);       -- see 3.6
      end record;

   type Square(Side : Integer) is new
      Matrix_Rec(Rows => Side, Columns => Side);

   type Double_Square(Number : Integer) is
      record
         Left  : Square(Number);
         Right : Square(Number);
      end record;

   task type Worker(Prio : System.Priority; Buf : access Buffer)
      with Priority => Prio is -- see D.1
         -- discriminants used to parameterize the task type (see 9.1)
      entry Fill;
      entry Drain;
   end Worker;

end ARM_3_7.Discriminants;