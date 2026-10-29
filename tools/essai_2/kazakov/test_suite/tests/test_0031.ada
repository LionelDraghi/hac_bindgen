--
-- ARM 3.9_1(11-17) Type Extensions
--
-- Success: 29:1..61:30 Tree *
--
-- package ARM_3_9_1.Type_Extensions is
--    type Painted_Point is new Point with
--      record
--        Paint : Color := White;
--      end record;
--    Origin : constant Painted_Point := (X | Y => 0.0, Paint => Black);
--    type Literal is new Expression with
--      record
--        Value : Real;
--      end record;
--    type Expr_Ptr is access all Expression'Class;
--    type Binary_Operation is new Expression with
--      record
--        Left, Right : Expr_Ptr;
--      end record;
--    type Addition is new Binary_Operation with null record;
--    type Subtraction is new Binary_Operation with null record;
--    Tree : Expr_Ptr :=
--       new (Addition'(Left  => new (Literal'(Value => 5.0)),
--          Right => new (Subtraction'(Left  => new (Literal'(Value => 13.0)),
--             Right => new (Literal'(Value => 7.0))))));
-- end ARM_3_9_1.Type_Extensions;
--
package ARM_3_9_1.Type_Extensions is
   type Painted_Point is new Point with
     record
       Paint : Color := White;
     end record;
    -- Components X and Y are inherited

   Origin : constant Painted_Point := (X | Y => 0.0, Paint => Black);

   type Literal is new Expression with
     record               -- a leaf in an Expression tree
       Value : Real;
     end record;

   type Expr_Ptr is access all Expression'Class;
                             -- see 3.9 3.10

   type Binary_Operation is new Expression with
     record               -- an internal node in an Expression tree
       Left, Right : Expr_Ptr;
     end record;

   type Addition is new Binary_Operation with null record;
   type Subtraction is new Binary_Operation with null record;
  -- No additional components needed for these extensions

   Tree : Expr_Ptr :=     -- A tree representation of “5.0 + (13.0–7.0)”
      new Addition'(
         Left  => new Literal'(Value => 5.0),
         Right => new Subtraction'(
            Left  => new Literal'(Value => 13.0),
            Right => new Literal'(Value => 7.0)));
end ARM_3_9_1.Type_Extensions;