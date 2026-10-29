--
-- ARM 11.2 Exception Handlers
--
-- Success: 18:1..28:13 Tree *
--
-- procedure ARM_11_2 is
-- begin
--    begin
--       Open (File, In_File, "input.txt");
--    exception
--       when E : Name_Error =>
--          Put ("Cannot open input file : ");
--          Put_Line (Ada.Exceptions.Exception_Message);
--          raise;
--    end;
-- end ARM_11_2;
--
procedure ARM_11_2 is
begin
   begin
      Open(File, In_File, "input.txt");   -- see A.8.2
   exception
      when E : Name_Error =>
         Put("Cannot open input file : ");
         Put_Line(Ada.Exceptions.Exception_Message);  -- see 11.4.1
         raise;
   end;
end ARM_11_2;