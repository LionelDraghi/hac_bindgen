--
-- ARM 5.6.1(9) Parallel Block Statements
--
-- Success: 32:1..59:11 Tree *
--
-- function Search (S : String; Char : Character) return Boolean is
-- begin
--    if (S'Length <= 1000) then
--        return (for some C of S => (C = Char));
--    else
--        declare
--           Mid : constant Positive := (S'First + (S'Length / 2) + 0-(1));
--        begin
--           parallel do
--              for C of S (S'First..Mid) loop
--                 if (C = Char) then
--                    return True;
--                 end if;
--              end loop;
--           and
--              for C of S ((Mid + 1)..S'Last) loop
--                 if (C = Char) then
--                    return True;
--                 end if;
--              end loop;
--           end do;
--           return False;
--        end;
--    end if;
-- end Search;
--
function Search (S : String; Char : Character) return Boolean is
begin
   if S'Length <= 1000 then
       -- Sequential scan
       return (for some C of S => C = Char);
   else
       -- Parallel divide and conquer
       declare
          Mid : constant Positive := S'First + S'Length/2 - 1;
       begin
          parallel do
             for C of S(S'First .. Mid) loop
                if C = Char then
                   return True;  -- Terminates enclosing do
                end if;
             end loop;
          and
             for C of S(Mid + 1 .. S'Last) loop
                if C = Char then
                   return True;  -- Terminates enclosing do
                end if;
             end loop;
          end do;
          -- Not found
          return False;
       end;
   end if;
end Search;