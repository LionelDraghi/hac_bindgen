--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Formal_Type              Spring, 2026       --
--  Implementation                                                    --
--                                Last revision :  19:35 03 Aug 2026  --
--                                                                    --
--  This  library  is  free software; you can redistribute it and/or  --
--  modify it under the terms of the GNU General Public  License  as  --
--  published by the Free Software Foundation; either version  2  of  --
--  the License, or (at your option) any later version. This library  --
--  is distributed in the hope that it will be useful,  but  WITHOUT  --
--  ANY   WARRANTY;   without   even   the   implied   warranty   of  --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU  --
--  General  Public  License  for  more  details.  You  should  have  --
--  received  a  copy  of  the GNU General Public License along with  --
--  this library; if not, write to  the  Free  Software  Foundation,  --
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.    --
--                                                                    --
--  As a special exception, if other files instantiate generics from  --
--  this unit, or you link this unit with other files to produce  an  --
--  executable, this unit does not by  itself  cause  the  resulting  --
--  executable to be covered by the GNU General Public License. This  --
--  exception  does not however invalidate any other reasons why the  --
--  executable file might be covered by the GNU Public License.       --
--____________________________________________________________________--

with Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Formal_Type return Tokens.Argument_Token is

   Result        : Tokens.Argument_Token;
   Name          : Tokens.Argument_Token;
   Discriminants : Parameter_Profile_Ref;

   function Get_Default return Formal_Type_Default is
   begin
      if Get ("or") then
         if not Get ("use") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'use' is expected after 'or' at " & Image (Link (Code))
            );
         end if;
         declare
            Mark : Subtype_Mark;
         begin
            Get_Subtype_Mark
            (  Context  => Context,
               Code     => Code,
               No_Range => True,
               Not_Null => False,
               Mark     => Mark
            );
            return
            (  Defaulted => True,
               Default   => Mark
            );
         end;
      else
         return (Defaulted => False);
      end if;
   end Get_Default;

   procedure Get_Access (Not_Null : Boolean) is
      Definition : constant Anonymous_Access_Definition :=
                            Get_Anonymous_Access_Definition
                            (  Context   => Context'Access,
                               Code      => Code'Access,
                               File      => File,
                               Not_Null  => Not_Null,
                               Parent    => Enclosing,
                               To_Object => True
                            );
   begin
      if Discriminants /= null then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Formal access type is not alloved to have " &
            "discriminant part found at "                &
            Image (Discriminants.Location)
         );
      end if;
      declare
         type Arena_Ptr is access Formal_Access_Type_Parameter;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Default : constant Formal_Type_Default := Get_Default;
         Ptr     : constant Arena_Ptr :=
                   new Formal_Access_Type_Parameter
                       (  Mode          => Definition.Mode,
                          Not_Null      => Definition.Not_Null,
                          Defaulted     => Default.Defaulted,
                          Aspects_Count => Get_Aspects_Count
                       );
         This : Formal_Access_Type_Parameter renames Ptr.all;
      begin
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         This.Pointer    := Definition;
         Add_Outer (This.Pointer, This, Parent);
         This.Default    := Default;
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Result.Location & Link (Code);
         This.Location   := Result.Location;
      end;
   end Get_Access;

   procedure Get_Box is
   begin
      if not Get ("<>", False) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'<>' is expected at " & Image (Link (Code))
         );
      end if;
   end Get_Box;

   procedure Get_Derived_Type
             (  Abstract_Type : Boolean;
                Mode          : Derived_Interface_Type
             )  is
      Target : Tokens.Argument_Token;
      Count  : Natural := 0;

      procedure Set (This : in out Formal_Derived_Type_Parameter) is
      begin
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         if Discriminants /= null then
            Discriminants.Outer := This'Unchecked_Access;
            This.Discriminants  := Discriminants.all'Unchecked_Access;
         end if;
         This.Parent_Type := Target;
         Pop (Context, This.Aspects);
         Pop (Context, This.Interfaces);
      end Set;
   begin
      Get_Expanded_Name (Context, Code, True, Target);
      Count := Get_Interfaces_List
               (  Context => Context'Access,
                  Code    => Code'Access,
                  Prefix  => "and"
               );
      if Get ("with") then
         if Get ("private") then
            declare
               type Arena_Ptr is access Formal_Derived_Type_Parameter;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Default : constant Formal_Type_Default := Get_Default;
               Ptr     : constant Arena_Ptr :=
                         new Formal_Derived_Type_Parameter
                             (  Abstract_Type    => Abstract_Type,
                                With_Private     => True,
                                Mode             => Mode,
                                Interfaces_Count => Count,
                                Defaulted        => Default.Defaulted,
                                Aspects_Count    => Get_Aspects_Count
                             );
               This : Formal_Derived_Type_Parameter renames Ptr.all;
            begin
               Set (This);
               This.Default := Default;
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         elsif Count > 0 then -- With may introduce aspects
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'private' is expected after 'with' at " &
                  Image (Link (Code))
               );
         else
            declare
               type Arena_Ptr is access Formal_Derived_Type_Parameter;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Default : constant Formal_Type_Default := Get_Default;
               Ptr     : constant Arena_Ptr :=
                         new Formal_Derived_Type_Parameter
                             (  Abstract_Type    => Abstract_Type,
                                With_Private     => False,
                                Mode             => Mode,
                                Interfaces_Count => Count,
                                Defaulted        => Default.Defaulted,
                                Aspects_Count    => Get_Aspects_Count
                             );
               This : Formal_Derived_Type_Parameter renames Ptr.all;
            begin
               Set (This);
               This.Default    := Default;
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         end if;
      elsif Count > 0 then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'with' is expected at " & Image (Link (Code))
         );
      else
         declare
            type Arena_Ptr is access Formal_Derived_Type_Parameter;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Default : constant Formal_Type_Default := Get_Default;
            Ptr     : constant Arena_Ptr :=
                      new Formal_Derived_Type_Parameter
                          (  Abstract_Type    => Abstract_Type,
                             With_Private     => False,
                             Mode             => Mode,
                             Interfaces_Count => Count,
                             Defaulted        => Default.Defaulted,
                             Aspects_Count    => Get_Aspects_Count
                          );
            This : Formal_Derived_Type_Parameter renames Ptr.all;
         begin
            Set (This);
            This.Default    := Default;
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      end if;
   end Get_Derived_Type;

   procedure Get_Incomplete_Type (Tagged_Type : Boolean) is
      type Arena_Ptr is access Formal_Incomplete_Type_Parameter;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Default : constant Formal_Type_Default := Get_Default;
      Ptr     : constant Arena_Ptr :=
                new Formal_Incomplete_Type_Parameter
                    (  Tagged_Type => Tagged_Type,
                       Defaulted   => Default.Defaulted
                    );
      This : Formal_Incomplete_Type_Parameter renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      if Discriminants /= null then
         Discriminants.Outer := This'Unchecked_Access;
         This.Discriminants  := Discriminants.all'Unchecked_Access;
      end if;
      This.Default    := Default;
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Result.Location & Link (Code);
      This.Location   := Result.Location;
   end Get_Incomplete_Type;

   procedure Get_Interface_Type (Mode : Interface_Type) is
      type Arena_Ptr is access Formal_Interface_Type_Parameter;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Count : constant Natural := Get_Interfaces_List
                                  (  Context => Context'Access,
                                     Code    => Code'Access,
                                     Prefix  => "and"
                                  );
      Default : constant Formal_Type_Default := Get_Default;
      Ptr     : constant Arena_Ptr :=
                new Formal_Interface_Type_Parameter
                    (  Mode             => Mode,
                       Interfaces_Count => Count,
                       Defaulted        => Default.Defaulted,
                       Aspects_Count    => Get_Aspects_Count
                    );
      This : Formal_Interface_Type_Parameter renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      if Discriminants /= null then
         Discriminants.Outer := This'Unchecked_Access;
         This.Discriminants  := Discriminants.all'Unchecked_Access;
      end if;
      This.Default := Default;
      Pop (Context, This.Aspects);
      Pop (Context, This.Interfaces);
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Result.Location & Link (Code);
      This.Location   := Result.Location;
   end Get_Interface_Type;

   procedure Get_Private_Type
             (  Abstract_Type : Boolean;
                Tagged_Type   : Boolean;
                Limited_Type  : Boolean;
                Need_Private  : Boolean
             )  is
      type Arena_Ptr is access Formal_Private_Type_Parameter;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Default : constant Formal_Type_Default := Get_Default;
      Ptr     : constant Arena_Ptr :=
                new Formal_Private_Type_Parameter
                    (  Abstract_Type => Abstract_Type,
                       Limited_Type  => Limited_Type,
                       Tagged_Type   => Tagged_Type,
                       Defaulted     => Default.Defaulted,
                       Aspects_Count => Get_Aspects_Count
                    );
      This : Formal_Private_Type_Parameter renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      if Discriminants /= null then
         Discriminants.Outer := This'Unchecked_Access;
         This.Discriminants  := Discriminants.all'Unchecked_Access;
      end if;
      This.Default := Default;
      Pop (Context, This.Aspects);
      if Need_Private and then not Get ("private") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'private' is expected at " & Image (Link (Code))
         );
      end if;
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Result.Location & Link (Code);
      This.Location   := Result.Location;
   end Get_Private_Type;

   procedure Get_Scalar_Type (Kind_Of : Formal_Scalar_Type) is
   begin
      if Discriminants /= null then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Disciminant part is not alloved for " &
            Image (Kind_Of)                        &
            " found at "                           &
            Image (Discriminants.Location)
         );
      end if;
      declare
         type Arena_Ptr is access Formal_Scalar_Type_Parameter;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Default : constant Formal_Type_Default := Get_Default;
         Ptr     : constant Arena_Ptr :=
                   new Formal_Scalar_Type_Parameter
                       (  Kind_Of       => Kind_Of,
                          Defaulted     => Default.Defaulted,
                          Aspects_Count => Get_Aspects_Count
                       );
         This : Formal_Scalar_Type_Parameter renames Ptr.all;
      begin
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         This.Default := Default;
         Pop (Context, This.Aspects);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Result.Location & Link (Code);
         This.Location   := Result.Location;
      end;
   end Get_Scalar_Type;

   Keyword : Reserved_Word;
begin
   Result.Location := Before (Code);
   Get_Simple_Name (Context, Code, True, Name);
   Discriminants := Get_Procedure_Profile
                    (  Context   => Context'Access,
                       Code      => Code'Access,
                       File      => File,
                       Parent    => Enclosing,
                       Unknown   => True,
                       No_Access => False,
                       Profile   => False
                    );
   if Get ("is") then
      if Get ("(<>)", False) then -- Formal discrete type
         Get_Scalar_Type (Formal_Discrete_Type);
      else
         Get_Reserved_Word (Code, Keyword);
         if Context.Trace /= null then
            Parsers.Multiline_Source.Location_Text_IO.Put_Line
            (  Code    => Code,
               File    => Context.Trace.all,
               Message => " ---generic-type-----------" &
                          Reserved_Word'Image (Keyword) &
                          " in "                        &
                          Image (Kind_Of)               &
                          Natural'Image (Get_Arguments_Count (Context))
            );
         end if;
         case Keyword is
            when Abstract_Word =>
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               case Keyword is
                  when Limited_Word =>
                     if not Get ("new") then
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'new' is expected after " &
                           "'abstract limited' at "   &
                           Image (Link (Code))
                        );
                     end if;
                     Get_Derived_Type (True, Limited_Interface);
                  when Synchronized_Word =>
                     if not Get ("new") then
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'new' is expected after "     &
                           "'abstract synchronized at "   &
                           Image (Link (Code))
                        );
                     end if;
                     Get_Derived_Type (True, Synchronized_Interface);
                  when New_Word =>
                     Get_Derived_Type (True, Any_Interface);
                  when Tagged_Word =>
                     Get_Private_Type
                     (  Abstract_Type => True,
                        Tagged_Type   => True,
                        Limited_Type  => Get ("limited"),
                        Need_Private  => True
                     );
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'limited', 'new', 'synchronized', 'tagged' " &
                        "is expected after 'abstract' at "            &
                        Image (Link (Code))
                     );
               end case;
            when Access_Word =>
               Get_Access (Not_Null => False);
            when Array_Word =>
               if Discriminants /= null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "A formal array type is not alloved to have " &
                     "discriminant part found at "                 &
                     Image (Discriminants.Location)
                  );
               end if;
               declare
                  type Arena_Ptr is access Formal_Array_Type_Parameter;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Definition : constant Array_Type_Specification_Ptr :=
                                        Get_Array_Type_Definition
                                        (  Context => Context'Access,
                                           Code    => Code'Access,
                                           File    => File,
                                           Parent  => Parent
                                        );
                  Default : constant Formal_Type_Default := Get_Default;
                  Ptr     : constant Arena_Ptr :=
                     new Formal_Array_Type_Parameter
                         (  Defaulted     => Default.Defaulted,
                            Aspects_Count => Get_Aspects_Count
                         );
                  This : Formal_Array_Type_Parameter renames Ptr.all;
               begin
                  Set
                  (  Context,
                     Name,
                     Enclosing,
                     File,
                     This,
                     This.Name'Access
                  );
                  This.Default    := Default;
                  This.Definition := Definition;
                  Add_Outer (This.Definition.all, This, Parent);
                  Pop (Context, This.Aspects);
                  Get_Semicolon (Context, Code);
                  Result.Value    := This'Unchecked_Access;
                  Result.Location := Result.Location & Link (Code);
                  This.Location   := Result.Location;
               end;
            when Delta_Word =>
               Get_Box;
               if Get ("digits") then
                  Get_Box;
                  Get_Scalar_Type (Formal_Decimal_Fixed_Point_Type);
               else
                  Get_Scalar_Type (Formal_Ordinal_Fixed_Point_Type);
               end if;
            when Digits_Word =>
               Get_Box;
               Get_Scalar_Type (Formal_Floating_Point_Type);
            when Interface_Word =>
               Get_Interface_Type (Any_Interface);
            when Limited_Word =>
               if Get ("new") then
                  Get_Derived_Type (False, Limited_Interface);
               elsif Get ("interface") then
                  Get_Interface_Type (Limited_Interface);
               else
                  Get_Private_Type
                  (  Abstract_Type => False,
                     Tagged_Type   => False,
                     Limited_Type  => True,
                     Need_Private  => True
                  );
               end if;
            when Mod_Word =>
               Get_Box;
               Get_Scalar_Type (Formal_Modular_Type);
            when New_Word =>
               Get_Derived_Type (False, Any_Interface);
            when Not_Word =>
               if not Get ("null") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'null' is expected after 'not' is expected " &
                     Image (Link (Code))
                  );
               elsif not Get ("access") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'access' is expected after 'not null' " &
                     "is expected " &
                     Image (Link (Code))
                  );
               end if;
               Get_Access (Not_Null => False);
            when Private_Word =>
               Get_Private_Type
               (  Abstract_Type => False,
                  Tagged_Type   => False,
                  Limited_Type  => False,
                  Need_Private  => False
               );
            when Range_Word =>
               Get_Box;
               Get_Scalar_Type (Formal_Integer_Type);
            when Synchronized_Word =>
               if Get ("new") then
                  Get_Derived_Type (False, Synchronized_Interface);
               elsif Get ("interface") then
                  Get_Interface_Type (Synchronized_Interface);
               end if;
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'new' or 'interface' is expected after " &
                  "'synchronized' at "                      &
                  Image (Link (Code))
               );
            when Tagged_Word =>
               if Get ("limited") then
                  Get_Private_Type
                  (  Abstract_Type => False,
                     Tagged_Type   => True,
                     Limited_Type  => True,
                     Need_Private  => True
                  );
               elsif Get ("private") then
                  Get_Private_Type
                  (  Abstract_Type => False,
                     Tagged_Type   => True,
                     Limited_Type  => False,
                     Need_Private  => False
                  );
               else
                  Get_Incomplete_Type (True);
               end if;
            when Task_Word =>
               if not Get ("interface") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'interface' is expected after 'task' at " &
                     Image (Link (Code))
                  );
               end if;
               Get_Interface_Type (Task_Interface);
            when No_Reserved_Word =>
               Get_Incomplete_Type (False);
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "A formal type definition after 'is' is " &
                  "expected at " &
                  Image (Link (Code))
               );
         end case;
      end if;
   else
      Get_Incomplete_Type (False);
   end if;
   return Result;
end Get_Formal_Type;
