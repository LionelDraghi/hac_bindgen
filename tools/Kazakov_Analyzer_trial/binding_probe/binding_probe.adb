--  Binding_Probe -- Driver probing what the Kazakov Ada syntax analyzer
--                  extracts from a package specification, at the level of
--  detail needed to build a HAC (scripting) binding model.
--
--  It parses a package specification, then dumps, for every declaration in
--  the public and private parts:
--     - the declaration class (Program_Node_Class) and source position;
--     - for subprograms: parameters with names, modes and types, and the
--       result type of functions;
--     - for types: enumeration literals, subtype base type and range;
--     - for objects: type and initial value expression;
--     - a resolution line showing what the analyzer's Find (name, use
--       location) yields for every referenced type name.
--
with Ada.Command_Line;             use Ada.Command_Line;
with Ada.Exceptions;               use Ada.Exceptions;
with Ada.Strings;                  use Ada.Strings;
with Ada.Strings.Fixed;            use Ada.Strings.Fixed;
with Ada.Strings.Maps;             use Ada.Strings.Maps;
with Ada.Text_IO;                  use Ada.Text_IO;

with Parsers.Ada_Syntax_Analyzer;
use  Parsers.Ada_Syntax_Analyzer;

with Parsers.Ada_Syntax_Analyzer.Declarations;
use  Parsers.Ada_Syntax_Analyzer.Declarations;

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

with Parsers.Ada_Syntax_Analyzer.Declarations.Types;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Types;

with Parsers.Multiline_Source;
use  Parsers.Multiline_Source;

with Parsers.Multiline_Source.Text_IO;

with Stack_Storage;

procedure Binding_Probe is
   use Parsers.Multiline_Source.Text_IO;
   use Ada_Expression_Parser;

   Default_Input : constant String := "../probe_fixture.ads";
   File_Name     : constant String :=
      (if Argument_Count > 0 then Argument (1) else Default_Input);

   Arena   : aliased Stack_Storage.Pool (4096, 128);
   Xref    : aliased Cross_Reference (Arena'Access);
   Program : aliased Ada_Program (Arena'Access, Xref'Unchecked_Access);

   Source_File : aliased Ada.Text_IO.File_Type;

   function Trimmed (Item : String) return String is
   begin
      return Trim (Item, Both);
   end Trimmed;

   function Location_Image (Where : Parsers.Multiline_Source.Location)
      return String is
   begin
      return Trimmed (Integer'Image (Integer (Where.First.Line)))
          & ":"
          & Trimmed (Integer'Image (Where.First.Column));
   end Location_Image;

   function Name_Of (Item : Defining_Identifier) return String is
   begin
      if Item.Name = null then
         return "<no name>";
      end if;
      return Item.Name.Value;
   end Name_Of;

   function Token_Image
            (  Token : Ada_Expression_Parser.Tokens.Argument_Token
            )  return String is
   begin
      if Token.Value = null then
         return "<missing>";
      end if;
      return Image (Token.Value.all);
   end Token_Image;

   --
   -- Report_Resolution -- Show what the analyzer's cross-reference yields
   --                      for a name used at a given location. This is name
   --                      resolution within the parsed sources only.
   --
   procedure Report_Resolution (Name : String; Where : Location) is
      use Context_Location_Sets;
      Set : Context_Location_Sets.Set := Find (Xref, Name, Where);
      Id  : Defining_Identifier_Ptr;
      Ptr : Declaration_Ptr;
   begin
      if Get_Size (Set) = 0 then
         Put_Line
         (  "      resolution : NONE for '"
         &  Name
         &  "' (not declared in the parsed sources)"
         );
      else
         for Index in 1 .. Get_Size (Set) loop
            Id  := Get (Set, Index);
            Ptr := Get (Id.Declared);
            if Index > 1 then
               Put ("                   or ");
            else
               Put ("      resolution : ");
            end if;
            Put_Line
            (  "'"
            &  Name
            &  "' -> "
            &  Trimmed
                  (  Program_Node_Class'Image
                        (  Program_Node_Class'
                              (Get_Class (Ptr.all))))
            &  " '"
            &  Name_Of (Id.all)
            &  "' at "
            &  Location_Image (Ptr.all.Location)
            );
         end loop;
      end if;
   end Report_Resolution;

   --
   -- Dump_Profile -- Dump the parameter profile of a subprogram
   --
   procedure Dump_Profile (This : Subprogram_Specification'Class) is
      Profile : Parameter_Profile renames This.Profile.all;
   begin
      Put_Line ("      name       : " & Name_Of (This.Name));
      for Index in Profile.List'Range loop
         declare
            Spec : Parameter_Specification renames Profile.List (Index).all;
         begin
            for J in Spec.Parameters'Range loop
               Put_Line
               (  "      parameter  : "
               &  Name_Of (Spec.Parameters (J))
               &  " (name at "
               &  Location_Image (Spec.Parameters (J).Term.Location)
               &  ")");
            end loop;
            Put_Line ("      mode       : " & Image (Spec.Mode));
            case Spec.Mode is
               when In_Mode | Inout_Mode | Out_Mode =>
                  Put_Line ("      type       : " & Image (Spec.Value));
                  Report_Resolution
                     (  Image (Spec.Value),
                        Spec.Value.Name.Location);
               when Access_Mode =>
                  Put_Line
                  (  "      type       : "
                  &  Image (Spec.Mode)
                  &  " (anonymous access definition)");
            end case;
            if Spec.Defaulted then
               Put_Line
               (  "      default    : "
               &  Token_Image (Spec.Default.Item));
            end if;
         end;
      end loop;
   end Dump_Profile;

   --
   -- Dump_Item -- Dump one declaration item
   --
   procedure Dump_Item (Item : Declaration_Node'Class) is
   begin
      Put_Line
      (  "    - "
      &  Trimmed
            (  Program_Node_Class'Image
                  (Program_Node_Class' (Get_Class (Item))))
      &  "  at "
      &  Location_Image (Item.Location));
      case Program_Node_Class' (Get_Class (Item)) is
         when With_Clause_Node =>
            declare
               This : With_Clause renames With_Clause (Item);
            begin
               Put ("      units      : ");
               for Index in This.List'Range loop
                  if Index > This.List'First then
                     Put (", ");
                  end if;
                  Put (Token_Image (This.List (Index)));
               end loop;
               New_Line;
            end;
         when Subtype_Declaration_Node =>
            declare
               This : Subtype_Declaration renames Subtype_Declaration (Item);
               Mark : Subtype_Mark renames This.Indication.Mark;
            begin
               Put_Line ("      name       : " & Name_Of (This.Name));
               Put_Line
               (  "      indication : "
               &  Image (This.Indication));
               case This.Indication.Mode is
                  when Subtype_Range_Mode =>
                     Put_Line
                     (  "      base type  : "
                     &  Image (Mark));
                     Put_Line
                     (  "      constraint : range "
                     &  Token_Image (This.Indication.Range_Constraint));
                  when Subtype_Mode =>
                     Put_Line ("      base type  : " & Image (Mark));
                  when Range_Mode =>
                     Put_Line
                     (  "      constraint : "
                     &  Token_Image (This.Indication.Range_Constraint));
                  when Unconstrained_Mode =>
                     Put_Line ("      constraint : <>");
               end case;
               Report_Resolution (Image (Mark), Mark.Name.Location);
            end;
         when Enumeration_Type_Declaration_Node =>
            declare
               This : Enumeration_Type_Declaration renames
                         Enumeration_Type_Declaration (Item);
            begin
               Put_Line ("      name       : " & Name_Of (This.Name));
               Put ("      literals   : ");
               for Index in This.List'Range loop
                  if Index > This.List'First then
                     Put (", ");
                  end if;
                  Put (Token_Image (This.List (Index)));
               end loop;
               New_Line;
            end;
         when Procedure_Declaration_Node =>
            Dump_Profile (Procedure_Declaration (Item));
         when Function_Declaration_Node =>
            declare
               This : Function_Declaration renames
                         Function_Declaration (Item);
            begin
               Dump_Profile (This);
               Put_Line
               (  "      result     : "
               &  Image (This.Result.Result));
               Report_Resolution
               (  Image (This.Result.Result),
                  This.Result.Result.Name.Location);
            end;
         when Object_Declaration_Node =>
            declare
               This : Object_Declaration renames
                         Object_Declaration (Item);
               Definition : Object_Specification renames
                               This.Definition.all;
            begin
               Put ("      name       : ");
               for Index in This.Names'Range loop
                  if Index > This.Names'First then
                     Put (", ");
                  end if;
                  Put (Name_Of (This.Names (Index)));
               end loop;
               New_Line;
               Put_Line
               (  "      constant   : "
               &  Boolean'Image (This.Immutable));
               case Definition.Mode is
                  when Object_Mode =>
                     declare
                        Mark : Subtype_Mark renames
                                  Definition.Variable.Mark;
                     begin
                        Put_Line ("      type       : " & Image (Mark));
                        case Definition.Variable.Mode is
                           when Subtype_Range_Mode =>
                              Put_Line
                              (  "      constraint : range "
                              &  Token_Image
                                    (  Definition.Variable.
                                          Range_Constraint));
                           when Subtype_Mode =>
                              null;
                           when Range_Mode =>
                              Put_Line
                              (  "      constraint : "
                              &  Token_Image
                                    (  Definition.Variable.
                                          Range_Constraint));
                           when Unconstrained_Mode =>
                              Put_Line ("      constraint : <>");
                        end case;
                        Report_Resolution
                        (  Image (Mark),
                           Mark.Name.Location);
                     end;
                  when Constant_Mode =>
                     Put_Line
                     (  "      type       : <number declaration,"
                     &  " no subtype mark>");
                  when others =>
                     Put_Line
                     (  "      type       : "
                     &  Image (Definition.Mode));
               end case;
               if This.Initialized then
                  Put_Line
                  (  "      value      : "
                  &  Token_Image (This.Initial.Item));
               end if;
            end;
         when others =>
            Put_Line ("      (not dumped by the probe)");
      end case;
   end Dump_Item;

   --
   -- Dump_Context -- Dump all items of a declaration context
   --
   procedure Dump_Context (Context : Compilation_Context'Class) is
   begin
      for Index in 1 .. Get_Items_Number (Context) loop
         Dump_Item (Get_Item (Context, Index).all);
      end loop;
   end Dump_Context;

   Result : Ada_Expression_Parser.Tokens.Argument_Token;

begin
   Put_Line ("Kazakov Ada syntax analyzer - HAC binding probe");
   Put_Line ("source: " & File_Name);
   New_Line;
   Open (Source_File, In_File, File_Name);
   Set_Constant_Folding (Program, True);
   declare
      Code : aliased Parsers.Multiline_Source.Text_IO.Source
                        (Source_File'Access);
   begin
      Result := Parse (Program'Access, Code'Access);
   exception
      when Error : others =>
         Close (Source_File);
         Reraise_Occurrence (Error);
   end;
   Close (Source_File);

   if Result.Value = null
      or else Result.Value.all not in Package_Declaration
   then
      Put_Line ("ERROR: root node is not a package declaration");
      return;
   end if;

   declare
      Package_Decl : Package_Declaration renames
                        Package_Declaration (Result.Value.all);
      Unit : Context_Entry := Get_First (Xref);
      Unit_Decl : Declaration_Context renames
                     Declaration_Context (Get_Context (Unit).all);
   begin
      Put_Line
      (  "--- compilation unit context ("
      &  Trimmed (Compilation_Context_Type'Image (Unit_Decl.Kind_Of))
      &  ", scope at "
      &  Location_Image (Unit_Decl.Scope)
      &  ") ---");
      Dump_Context (Unit_Decl);
      New_Line;
      Put_Line
      (  "--- package "
      &  Name_Of (Package_Decl.Name)
      & " (declared at "
      &  Location_Image (Package_Decl.Location)
      &  ") : PUBLIC part (bindable, scope at "
      &  Location_Image (Package_Decl.Public_Part.Scope)
      &  ") ---");
      Dump_Context (Package_Decl.Public_Part.all);
      New_Line;
      if Package_Decl.Private_Part /= null then
         Put_Line
         (  "--- package "
         &  Name_Of (Package_Decl.Name)
         & " : PRIVATE part (NOT bindable, scope at "
         &  Location_Image (Package_Decl.Private_Part.Scope)
         &  ") ---");
         Dump_Context (Package_Decl.Private_Part.all);
      else
         Put_Line ("--- no private part ---");
      end if;
   end;
exception
   when Error : Parsers.Syntax_Error =>
      Put_Line ("SYNTAX ERROR: " & Exception_Message (Error));
   when Error : others =>
      Put_Line
      (  "FATAL: "
      &  Exception_Information (Error));
end Binding_Probe;
