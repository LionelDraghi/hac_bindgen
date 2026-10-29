--
-- ARM 5.6.1(7) Parallel Block Statements
--
-- Success: 22:1..36:13 Tree *
--
-- procedure Traverse (T : Expr_Ptr) is
-- begin
--    if ((T /= null) and then
--       T.all in Binary_Operation'Class)
--    then
--       parallel do
--          Traverse (T.Left);
--       and
--          Traverse (T.Right);
--       and
--          Ada.Text_IO.Put_Line
--             (("Processing " & Ada.Tags.Expanded_Name (T'Tag)));
--       end do;
--    end if;
-- end Traverse;
--
procedure Traverse (T : Expr_Ptr) is -- see 3.9.1
begin
   if T /= null and then
      T.all in Binary_Operation'Class -- see 3.9.1
   then -- recurse down the binary tree
      parallel do
         Traverse (T.Left);
      and
         Traverse (T.Right);
      and
         Ada.Text_IO.Put_Line
            ("Processing " & Ada.Tags.Expanded_Name (T'Tag));
      end do;
   end if;
end Traverse;