--
-- ARM 3.9(6-9) Tagged Types and Type Extensions
--
-- Success: 28:1..58:13 Tree *
--
-- package Ada.Tags
--    with Preelaborate, Nonblocking, Global => in out synchronized is
--    type Tag is private
--       with Preelaborable_Initialization;
--    No_Tag : constant Tag;
--    function Expanded_Name (T : Tag) return String;
--    function Wide_Expanded_Name (T : Tag) return Wide_String;
--    function Wide_Wide_Expanded_Name (T : Tag) return Wide_Wide_String;
--    function External_Tag (T : Tag) return String;
--    function Internal_Tag (External : String) return Tag;
--    function Descendant_Tag (External : String;
--                            Ancestor : Tag) return Tag;
--    function Is_Descendant_At_Same_Level (Descendant, Ancestor : Tag)
--        return Boolean;
--    function Parent_Tag (T : Tag) return Tag;
--    type Tag_Array is array (Positive range <>) of Tag;
--    function Interface_Ancestor_Tags (T : Tag) return Tag_Array;
--    function Is_Abstract (T : Tag) return Boolean;
--    Tag_Error : exception;
-- private
-- end Ada.Tags;
--
package Ada.Tags
   with Preelaborate, Nonblocking, Global => in out synchronized is
   type Tag is private
      with Preelaborable_Initialization;

   No_Tag : constant Tag;

   function Expanded_Name(T : Tag) return String;
   function Wide_Expanded_Name(T : Tag) return Wide_String;
   function Wide_Wide_Expanded_Name(T : Tag) return Wide_Wide_String;
   function External_Tag(T : Tag) return String;
   function Internal_Tag(External : String) return Tag;

   function Descendant_Tag(External : String;
                           Ancestor : Tag) return Tag;
   function Is_Descendant_At_Same_Level(Descendant, Ancestor : Tag)
       return Boolean;

   function Parent_Tag (T : Tag) return Tag;

   type Tag_Array is array (Positive range <>) of Tag;

   function Interface_Ancestor_Tags (T : Tag) return Tag_Array;

   function Is_Abstract (T : Tag) return Boolean;

   Tag_Error : exception;

private
   -- not specified by the language
end Ada.Tags;