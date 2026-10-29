--
-- ARM 10.1.3 Subunits of Compilation Units
--
-- Success: 28:1..30:11, 33:1..39:11, 41:1..44:11, 48:1..51:10 Tree *
--
-- package Parent is
--     procedure Inner;
-- end Parent;
-- with Ada.Text_IO;
-- package body Parent is
--     Variable : String := "Hello, there.";
--     procedure Inner is
--     begin
--         Ada.Text_IO.Put_Line (Variable);
--     end Inner;
-- end Parent;
-- package body Parent is
--     Variable : String := "Hello, there.";
--     procedure Inner is separate;
-- end Parent;
-- with Ada.Text_IO;
-- separate (Parent)
-- procedure Inner is
-- begin
--     Ada.Text_IO.Put_Line (Variable);
-- end Inner;
--
package Parent is
    procedure Inner;
end Parent;

with Ada.Text_IO;
package body Parent is
    Variable : String := "Hello, there.";
    procedure Inner is
    begin
        Ada.Text_IO.Put_Line(Variable);
    end Inner;
end Parent;

package body Parent is
    Variable : String := "Hello, there.";
    procedure Inner is separate;
end Parent;

with Ada.Text_IO;
separate(Parent)
procedure Inner is
begin
    Ada.Text_IO.Put_Line(Variable);
end Inner;