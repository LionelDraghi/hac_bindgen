--
-- ARM 5.2 Assignment Statements
--
-- Success: 27:1..52:12 Tree *
--
-- package body ARM_5_2 is
--    I, J : Integer range 1..10 := 5;
--    K    : Integer range 1..20 := 15;
-- 
--    A : String (1..31);
--    B : String (3..33);
-- begin
--    Value := (Max_Value - 1);
--    Shade := Blue;
--    Next_Frame (F) (M, N) := 2.5;
--    U := Dot_Product (V, W);
--    Writer := (Status => Open, Unit => Printer, Line_Count => 60);                                
--    Next.all := (72074, null, Head);
--    I := J;
--    K := J;
--    J := K;
--    A := B;
--    A (1..9) := "tar sauce";
--    A (4..12) := A (1..9);
-- end ARM_5_2;
--
package body ARM_5_2 is
   I, J : Integer range 1 .. 10 := 5;
   K    : Integer range 1 .. 20 := 15;

   A : String(1 .. 31);
   B : String(3 .. 33);
begin
   Value := Max_Value - 1;
   Shade := Blue;

   Next_Frame(F)(M, N) := 2.5;        -- see 4.1.1
   U := Dot_Product(V, W);            -- see 6.3

   Writer := (Status => Open, Unit => Printer, Line_Count => 60);
                                   -- see 3.8.1
   Next.all := (72074, null, Head);    -- see 3.10.1

   I := J;  -- identical ranges
   K := J;  -- compatible ranges
   J := K;  -- will raise Constraint_Error if K > 10

   A := B;  -- same number of components

   A(1 .. 9)  := "tar sauce";
   A(4 .. 12) := A(1 .. 9);  -- A(1 .. 12) = "tartar sauce"
end ARM_5_2;