--
-- ARM 5.5.3(31-33) Procedural Iterators
--
-- Success: 23:1..39:14 Tree *
--
-- package body ARM_4_5_3 is
-- begin
--    for (C : Cursor) of My_Map.Iterate loop
--       Put_Line ((My_Key_Type'Image (Key (C)) & " => " &
--          My_Element_Type'Image (Element (C))));
--    end loop;
--    declare
--       procedure P (C : Cursor) is
--       begin
--          Put_Line ((My_Key_Type'Image (Key (c)) & " => " &
--             My_Element_Type'Image (Element (C))));
--       end P;
--    begin
--       My_Map.Iterate (P'Access);
--    end;
-- end ARM_4_5_3;
--
package body ARM_4_5_3 is
begin
   for (C : Cursor) of My_Map.Iterate loop
      Put_Line (My_Key_Type'Image (Key (C)) & " => " &
         My_Element_Type'Image (Element (C)));
   end loop;
   -- The above is equivalent to:
   declare
      procedure P (C : Cursor) is
      begin
         Put_Line (My_Key_Type'Image (Key (c)) & " => " &
            My_Element_Type'Image (Element (C)));
      end P;
   begin
      My_Map.Iterate (P'Access);
   end;
end ARM_4_5_3;