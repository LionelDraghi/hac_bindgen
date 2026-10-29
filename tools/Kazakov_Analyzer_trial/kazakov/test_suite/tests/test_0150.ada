--
-- Tasks https://en.wikibooks.org/wiki/Ada_Programming/Tasking Ex.10
--
-- Success: 24:1..41:9
--
-- procedure WiKi is
--   task Password_Server is
--      entry Check (User, Pass : String; Valid : out Boolean);
--      entry Set (User, Pass : String);
--   end Password_Server;
--   User_Name, Password : String (1..8);
-- begin
--   Put ("Please give your new password:");
--   Get_Line (Password);
--   select
--      Password_Server.Set (User_Name, Password);
--      Put_Line ("Done");
--   or
--      delay 10.0;
--      Put_Line ("The system is busy now, please try again later.");
--   end select;
-- end WiKi;
--
procedure WiKi is
  task Password_Server is
     entry Check (User, Pass : in String; Valid : out Boolean);
     entry Set (User, Pass : in  String);
  end Password_Server;

  User_Name, Password : String (1 .. 8);
begin
  Put ("Please give your new password:");
  Get_Line (Password);
  select
     Password_Server.Set (User_Name, Password);
     Put_Line ("Done");
  or
     delay 10.0;
     Put_Line ("The system is busy now, please try again later.");
  end select;
end WiKi;