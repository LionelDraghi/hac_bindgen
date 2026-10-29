--
-- ARM 9.7.3 Conditional Entry Calls
--
-- Success: 18:1..28:4 Tree *
--
-- procedure Spin (R : in out Resource) is
-- begin
--    loop
--       select
--          R.Seize;
--          return;
--       else
--          null;
--       end select;
--    end loop;
-- end Spin;
--
procedure Spin(R : in out Resource) is  -- see 9.4
begin
   loop
      select
         R.Seize;
         return;
      else
         null;  --  busy waiting
      end select;
   end loop;
end;