--
-- ARM 4.3.5(87-91) Container Aggregates
--
-- Success: 21:1..39:14 Tree *
--
-- procedure ARM_4_3_5 is
--    V : Vector_Type;
-- begin
--    V := ["abc", "def"];
--    V := Empty_Vector (2);
--    Append_One (V, "abc");
--    Append_One (V, "def");
--    V := [1 => "this", 2 => "is", 3 => "a", 4 => "test"];
--    V := New_Vector (1, 4);
--    Assign_Element (V, 1, "this");
--    Assign_Element (V, 2, "is");
--    Assign_Element (V, 3, "a");
--    Assign_Element (V, 4, "test");
-- end ARM_4_3_5;
--
procedure ARM_4_3_5 is
   --  Example aggregates using Vector_Type.
   V : Vector_Type;
begin
   --  A positional vector aggregate:
   V := ["abc", "def"];
   --  Is equivalent to:
   V := Empty_Vector (2);
   Append_One (V, "abc");
   Append_One (V, "def");
   --  An indexed vector aggregate:
   V := [1 => "this", 2 => "is", 3 => "a", 4 => "test"];
   --  Is equivalent to:
   V := New_Vector (1, 4);
   Assign_Element (V, 1, "this");
   Assign_Element (V, 2, "is");
   Assign_Element (V, 3, "a");
   Assign_Element (V, 4, "test");
end ARM_4_3_5;