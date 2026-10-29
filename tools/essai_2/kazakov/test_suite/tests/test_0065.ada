--
-- ARM 5.5.3(35-37) Procedural Iterators
--
-- Success: 21:1..36:14 Tree *
--
-- package body ARM_4_5_3 is
-- begin
--    for (Name, Val) of Ada.Environment_Variables.Iterate (<>) loop
--       Put_Line ((Name & " => " & Val));
--    end loop;
--    declare
--       procedure P (Name : String; Val : String) is
--       begin
--          Put_Line ((Name & " => " & Val));
--       end P;
--    begin
--       Ada.Environment_Variables.Iterate (P'Access);
--    end;
-- end ARM_4_5_3;
--
package body ARM_4_5_3 is
begin
   for (Name, Val) of Ada.Environment_Variables.Iterate(<>) loop
      --  "(<>)" is optional because it is the last parameter
      Put_Line (Name & " => " & Val);
   end loop;
   -- The above is equivalent to:
   declare
      procedure P (Name : String; Val : String) is
      begin
         Put_Line (Name & " => " & Val);
      end P;
   begin
      Ada.Environment_Variables.Iterate (P'Access);
   end;
end ARM_4_5_3;