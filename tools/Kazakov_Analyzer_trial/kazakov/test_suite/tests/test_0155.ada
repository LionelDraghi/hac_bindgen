--
-- Object orientation https://en.wikibooks.org/wiki/Ada_Programming/Object_Orientation
--
-- Success: 74:1..106:8, 111:1..153:8             find A   at 77:5..5  = empty   
--                                                find B   at 101:5..5 = 100:1..102:2(1)
-- find P           at 101:26   = 100:1..102:2(2) find P   at 92:5..5  = empty
-- find X           at 124:5..5 = 122:35..63(1)   find CPP at 74:9..11 = 72:1..74:0(2)
-- find Public_Proc at 84:1     = 76:3..86:0(2)
-- find Public_Part at 95:1     = 76:3..86:0(1)
--
--  private with Ada.Finalization;
--  package CPP is
--    type Public_Part is abstract tagged record
--     A : Integer;
--   end record;
--   procedure Public_Proc (This : in out Public_Part);
--   type Complete_Type is new Public_Part with private;
-- private
--   type Private_Part;
--   type Private_Part_Pointer is access Private_Part;
--   type Private_Component is new Ada.Finalization.Controlled with record
--     P : Private_Part_Pointer;
--   end record;
--   overriding procedure Initialize (X : in out Private_Component);
--   overriding procedure Adjust     (X : in out Private_Component);
--   overriding procedure Finalize   (X : in out Private_Component);
--   type Complete_Type is new Public_Part with record
--     B : Integer;
--     P : Private_Component;
--   end record;
--   not overriding procedure Protected_Proc (This : Complete_Type);
-- end CPP;
-- 
-- with Ada.Unchecked_Deallocation;
-- with Ada.Text_IO;
-- package body CPP is
--   procedure Public_Proc (This : in out Public_Part) is
--   begin
--     Ada.Text_IO.Put_Line (("Public_Proc" & Integer'Image (This.A)));
--   end Public_Proc;
--   type Private_Part is record
--     C : Boolean;
--   end record;
--   overriding procedure Initialize (X : in out Private_Component) is
--   begin
--     X.P := new (Private_Part'(C => True));
--     Ada.Text_IO.Put_Line (("Initialize " & Boolean'Image (X.P.C)));
--   end Initialize;
--   overriding procedure Adjust (X : in out Private_Component) is
--   begin
--     Ada.Text_IO.Put_Line (("Adjust " & Boolean'Image (X.P.C)));
--     X.P := new (Private_Part'(C => X.P.C));
--   end Adjust;
--   overriding procedure Finalize (X : in out Private_Component) is
--     procedure Free is new Ada.Unchecked_Deallocation (Private_Part, Private_Part_Pointer);
--   begin
--     Ada.Text_IO.Put_Line (("Finalize " & Boolean'Image (X.P.C)));
--     Free (X.P);
--   end Finalize;
--   procedure Private_Proc (This : in out Complete_Type) is
--   begin
--     Ada.Text_IO.Put_Line (("Private_Proc" & Integer'Image (This.A) & Integer'Image (This.B) & ' ' & Boolean'Image (This.P.P.C)));
--   end Private_Proc;
--   not overriding procedure Protected_Proc (This : Complete_Type) is
--     X : Complete_Type := This;
--   begin
--     Ada.Text_IO.Put_Line (("Protected_Proc" & Integer'Image (This.A) & Integer'Image (This.B)));
--     Private_Proc (X);
--   end Protected_Proc;
-- end CPP;
--
private with Ada.Finalization;

package CPP is

  type Public_Part is abstract tagged record  -- no objects of this type
    A: Integer;
  end record;

  procedure Public_Proc (This: in out Public_Part);

  type Complete_Type is new Public_Part with private;

  -- procedure Public_Proc (This: in out Complete_Type);  -- inherited, implicitly find

private  -- visible for children

  type Private_Part;  -- declaration stub
  type Private_Part_Pointer is access Private_Part;

  type Private_Component is new Ada.Finalization.Controlled with record
    P: Private_Part_Pointer;
  end record;

  overriding procedure Initialize (X: in out Private_Component);
  overriding procedure Adjust     (X: in out Private_Component);
  overriding procedure Finalize   (X: in out Private_Component);

  type Complete_Type is new Public_Part with record
    B: Integer;
    P: Private_Component;  -- must be controlled to avoid storage leaks
  end record;

  not overriding procedure Protected_Proc (This: Complete_Type);

end CPP;

with Ada.Unchecked_Deallocation;
with Ada.Text_IO;

package body CPP is

  procedure Public_Proc (This: in out Public_Part) is  -- primitive
  begin
    Ada.Text_IO.Put_Line ("Public_Proc" & Integer'Image (This.A));
  end Public_Proc;

  type Private_Part is record  -- complete declaration
    C: Boolean;
  end record;

  overriding procedure Initialize (X: in out Private_Component) is
  begin
    X.P := new Private_Part'(C => True);
    Ada.Text_IO.Put_Line ("Initialize " & Boolean'Image (X.P.C));
  end Initialize;

  overriding procedure Adjust (X: in out Private_Component) is
  begin
    Ada.Text_IO.Put_Line ("Adjust " & Boolean'Image (X.P.C));
    X.P := new Private_Part'(C => X.P.C);  -- deep copy
  end Adjust;

  overriding procedure Finalize (X: in out Private_Component) is
    procedure Free is new Ada.Unchecked_Deallocation (Private_Part, Private_Part_Pointer);
  begin
    Ada.Text_IO.Put_Line ("Finalize " & Boolean'Image (X.P.C));
    Free (X.P);
  end Finalize;

  procedure Private_Proc (This: in out Complete_Type) is  -- not primitive
  begin
    Ada.Text_IO.Put_Line ("Private_Proc" & Integer'Image (This.A) & Integer'Image (This.B) & ' ' & Boolean'Image (This.P.P.C));
  end Private_Proc;

  not overriding procedure Protected_Proc (This: Complete_Type) is  -- primitive
    X: Complete_Type := This;
  begin
    Ada.Text_IO.Put_Line ("Protected_Proc" & Integer'Image (This.A) & Integer'Image (This.B));
    Private_Proc (X);
  end Protected_Proc;

end CPP;