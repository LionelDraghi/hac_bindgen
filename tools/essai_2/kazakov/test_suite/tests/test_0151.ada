--
-- Tasking https://en.wikibooks.org/wiki/Ada_Programming/Tasking
--
-- Success: 31:2..58:13
--
--  with printable_package; use printable_package;
--  procedure Printer is
--     type Printable is task interface;
--     procedure Input (D  : Printable);
--     task Process_Data is new Printable with
--        entry Input  (D  : Datum);
--        entry Output (D  : out Datum);
--     end Process_Data;
--     task type Print_Red  is new Printable with end Print_Red;
--     task type Print_Blue is new Printable with end Print_Blue;
--     task body Print_Red is
--     begin
--        Ada.Text_IO.Put_Line ("Printing in Red");
--     end Print_Red;
--     task body Print_Blue is
--     begin
--        Ada.Text_IO.Put_Line ("Printing in Blue");
--     end Print_Blue;
--     printer_task : access Printable'Class;
--  begin
--     printer_task := new (Print_Red);
--     printer_task := new (Print_Blue);
--  end Printer;
--
 with printable_package; use printable_package;  -- This package contains the definition of Printable
 procedure Printer is
    type Printable is task interface;

    procedure Input (D  : in  Printable);

    task Process_Data is new Printable with
       entry Input  (D  : in  Datum);
       entry Output (D  : out Datum);
    end Process_Data;

    task type Print_Red  is new Printable with end;
    task type Print_Blue is new Printable with end;
 
    task body Print_Red is
    begin
       Ada.Text_IO.Put_Line ("Printing in Red");
    end Print_Red;
 
    task body Print_Blue is
    begin
       Ada.Text_IO.Put_Line ("Printing in Blue");
    end Print_Blue;
 
    printer_task : access Printable'Class;
 begin
    printer_task := new Print_Red;
    printer_task := new Print_Blue;  -- Beware, this leaks memory. Example only.
 end Printer;