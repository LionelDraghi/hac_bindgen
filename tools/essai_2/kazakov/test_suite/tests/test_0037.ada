--
-- ARM 3.10(21-26) Access Types
--
-- Success: 21:1..39:13 Tree *
--
-- package body ARM_3_10 is
--    type Frame is access Matrix;
--    type Peripheral_Ref is not null access Peripheral;
--    type Binop_Ptr is access all Binary_Operation'Class;
--    subtype Drum_Ref is Peripheral_Ref (Drum);
--    type Message_Procedure is access procedure (M : String := "Error!");
--    procedure Default_Message_Procedure (M : String);
--    Give_Message : Message_Procedure := Default_Message_Procedure'Access;
--    procedure Other_Procedure (M : String);
-- begin
--    Give_Message := Other_Procedure'Access;
--    Give_Message ("File not found.");
--    Give_Message.all;
-- end ARM_3_10;
--
package body ARM_3_10 is
   type Frame is access Matrix;  -- see 3.6
   type Peripheral_Ref is not null access Peripheral;  -- see 3.8.1
   type Binop_Ptr is access all Binary_Operation'Class;
                              -- general access-to-class-wide, see 3.9.1
   subtype Drum_Ref is Peripheral_Ref(Drum); -- see 3.8.1

   type Message_Procedure is access procedure (M : in String := "Error!");
   procedure Default_Message_Procedure(M : in String);
   Give_Message : Message_Procedure := Default_Message_Procedure'Access;

   procedure Other_Procedure(M : in String);
begin
   Give_Message := Other_Procedure'Access;

   Give_Message("File not found.");
                            -- call with parameter (.all is optional)
   Give_Message.all;        -- call with no parameters
end ARM_3_10;