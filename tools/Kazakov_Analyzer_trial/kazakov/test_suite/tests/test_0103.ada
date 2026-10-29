--
-- ARM 9.4(20 b-d) Protected Units and Protected Objects
--
-- Success: 29:1..52:9 Tree *
--
-- procedure Main is
--     task T is
--         entry E;
--     end T;
--     task body T is
--         protected PO is
--             entry Ee;
--         end PO;
--         protected body PO is
--             entry Ee when False is
--             begin
--                 null;
--             end Ee;
--         end PO;
--     begin
--         accept E do
--             requeue PO.Ee;
--         end E;
--     end T;
-- begin
--     T.E;
-- end Main;
--
procedure Main is
    task T is
        entry E;
    end T;

    task body T is
        protected PO is
            entry Ee;
        end PO;

        protected body PO is
            entry Ee when False is
            begin
                null;
            end Ee;
        end PO;
    begin
        accept E do
            requeue PO.Ee;
        end E;
    end T;
begin
    T.E;
end Main;