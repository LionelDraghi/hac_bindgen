--
-- ARM 6.1 Subprogram Declarations
--
-- Success: 22:1..39:12 Tree *
--
-- package ARM_6_1 is
--    procedure Traverse_Tree;
--    procedure Increment (X : in out Integer);
--    procedure Right_Indent (Margin : out Line_Size);
--    procedure Switch (From, To : in out Link);
--    function Random return Probability;
--    function Min_Cell (X : Link) return Cell;
--    function Next_Frame (K : Positive) return Frame;
--    function Dot_Product (Left, Right : Vector) return Real;
--    function Find (B : aliased in out Barrel; Key : String) return Real;
--    function "*" (Left, Right : Matrix) return Matrix;
--    procedure Print_Header (Pages  : Natural;
--                Header : Line    :=  (1..Line'Last => ' ');
--                Center : Boolean := True);
-- end ARM_6_1;
--
package ARM_6_1 is
   procedure Traverse_Tree;
   procedure Increment(X : in out Integer);
   procedure Right_Indent(Margin : out Line_Size);          -- see 3.5.4
   procedure Switch(From, To : in out Link);                -- see 3.10.1

   function Random return Probability;                      -- see 3.5.7

   function Min_Cell(X : Link) return Cell;                 -- see 3.10.1
   function Next_Frame(K : Positive) return Frame;          -- see 3.10
   function Dot_Product(Left, Right : Vector) return Real;  -- see 3.6
   function Find(B : aliased in out Barrel; Key : String) return Real;
                                                            -- see 4.1.5
   function "*"(Left, Right : Matrix) return Matrix;        -- see 3.6
   procedure Print_Header(Pages  : in Natural;
               Header : in Line    :=  (1 .. Line'Last => ' '); -- see 3.6
               Center : in Boolean := True);
end ARM_6_1;