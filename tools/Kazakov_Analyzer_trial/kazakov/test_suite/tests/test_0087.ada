--
-- ARM 7.6.1(18.b) Completion and Finalization
--
-- Success: 30:1..52:9 Tree *
--
-- procedure Main is
-- begin
--     <<The_Label>>
--     Outer_Block_Statement : declare
--         X : Some_Controlled_Type;
--     begin
--         Inner_Block_Statement : declare
--             Y : Some_Controlled_Type;
--             Z : Some_Controlled_Type;
--         begin
--             goto The_Label;
--         exception
--             when Program_Error =>
--                null;
--         end Inner_Block_Statement;
--     exception
--         when Program_Error =>
--            null;
--     end Outer_Block_Statement;
-- exception
--     when Program_Error =>
--        null;
-- end Main;
--
procedure Main is
begin
    <<The_Label>>
    Outer_Block_Statement : declare
        X : Some_Controlled_Type;
    begin
        Inner_Block_Statement : declare
            Y : Some_Controlled_Type;
            Z : Some_Controlled_Type;
        begin
            goto The_Label;
        exception
            when Program_Error => -- Handler number 1.
               null;
        end Inner_Block_Statement;
    exception
        when Program_Error => -- Handler number 2.
           null;
    end Outer_Block_Statement;
exception
    when Program_Error => -- Handler number 3.
       null;
end Main;