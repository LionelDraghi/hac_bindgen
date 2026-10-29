--
-- Case statement
--
-- Success: 14:1..22:19
--
-- procedure Case_Statement is
-- begin
--    case Count is
--       when Positive range 1..2 => null;
--       when others => null;
--    end case;
-- end Case_Statement;
--
procedure Case_Statement is
begin
   case Count is
      when Positive range 1..2 =>
         null;
      when others =>
         null;
   end case;
end Case_Statement;
