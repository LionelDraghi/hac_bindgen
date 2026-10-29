--
-- Case statement
--
-- Success: 17:1..26:19
--
-- procedure Case_Statement is
-- begin
--    case S is
--       when ' '..'X' => null;
--       when 'A' | 'B' => null;
--       when Character'Val (1) => null;
--       when (1 + 3) => null;
--       when others => null;
--    end case;
-- end Case_Statement;
--
procedure Case_Statement is
begin
   case S is
      when ' '..'X' => null;
      when 'A' | 'B' => null;
      when Character'Val (1) => null;
      when 1 + 3 => null;
      when others => null;
   end case;
end Case_Statement;