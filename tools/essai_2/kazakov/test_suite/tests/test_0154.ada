--
-- Object orientation https://en.wikibooks.org/wiki/Ada_Programming/Object_Orientation
--
-- Success: 26:1..37:15 find Object           at 27:9..14  = empty
--                      find Class_Member_1   at 35:14..27 = 27:4..37:0(2)
--                      find New_Class_Member at 37:0      = 27:4..37:0(3)
--                      find Skilled_In       at 31:23..35 = empty
--                      find Skilled_In       at 32:1..1   = 31:1..32:6(1)
--                      find Programmer       at 27:1      = 25:1..26:0(2)
--
--  with Person;
--  package Programmer is
--     type Object is new Person.Object
--                    and Printable.Object
--     with
--        record
--           Skilled_In : Language_List;
--        end record;
--     overriding
--     procedure Class_Member_1   (This : Object);
--     not overriding
--     procedure New_Class_Member (This : Object; That : String);
--  end Programmer;
--
with Person;
package Programmer is
   type Object is new Person.Object
                  and Printable.Object
   with
      record
         Skilled_In : Language_List;
      end record;
   overriding
   procedure Class_Member_1   (This : in Object);
   not overriding
   procedure New_Class_Member (This : Object; That : String);
end Programmer;
