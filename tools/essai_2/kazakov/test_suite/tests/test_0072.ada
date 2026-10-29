--
-- ARM 6.3(9) Subprogram Bodies
--
-- Success: 16:1..24:9 Tree *
--
-- procedure Push (E : Element_Type; S : in out Stack) is
-- begin
--    if (S.Index = S.Size) then
--       raise Stack_Overflow;
--    else
--       S.Index := (S.Index + 1);
--       S.Space (S.Index) := E;
--    end if;
-- end Push;
--
procedure Push(E : in Element_Type; S : in out Stack) is
begin
   if S.Index = S.Size then
      raise Stack_Overflow;
   else
      S.Index := S.Index + 1;
      S.Space(S.Index) := E;
   end if;
end Push;