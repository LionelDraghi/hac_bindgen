--
-- Protected object https://en.wikibooks.org/wiki/Ada_Programming/Tasking Ex.5
--
-- Success: 32:1..57:9
--
-- procedure WiKi is
--   protected type Protected_Buffer_Type is
--      entry Insert (An_Item : Item);
--      entry Remove (An_Item : out Item);
--   private
--      Buffer : Item;
--      Empty  : Boolean := True;
--   end Protected_Buffer_Type;
--   protected body Protected_Buffer_Type is
--      entry Insert (An_Item : Item)
--         when Empty is
--      begin
--         Buffer := An_Item;
--         Empty := False;
--      end Insert;
--      entry Remove (An_Item : out Item)
--         when not (Empty) is
--      begin
--         An_Item := Buffer;
--         Empty := True;
--      end Remove;
--   end Protected_Buffer_Type;
-- begin
--   null;
-- end WiKi;
--
procedure WiKi is
  protected type Protected_Buffer_Type is
     entry Insert (An_Item : in  Item);
     entry Remove (An_Item : out Item);
  private
     Buffer : Item;
     Empty  : Boolean := True;
  end Protected_Buffer_Type;

  protected body Protected_Buffer_Type is
     entry Insert (An_Item : in  Item)
        when Empty is
     begin
        Buffer := An_Item;
        Empty := False;
     end Insert;
     entry Remove (An_Item : out Item)
        when not Empty is
     begin
        An_Item := Buffer;
        Empty := True;
     end Remove;
  end Protected_Buffer_Type;
begin
   null;
end WiKi;
