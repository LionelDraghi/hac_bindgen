--
-- ARM 4.3.5(55-65) Container Aggregates
--
-- Success: 34:1..77:14 Tree *
--
-- package ARM_4_3_5 is
--    type Set_Type is private
--        with Aggregate => (Empty       => Empty_Set,
--                           Add_Unnamed => Include);
--     function Empty_Set return Set_Type;
--     subtype Small_Int is Integer range -(1000)..1000;
--     procedure Include (S : in out Set_Type; N : Small_Int);
--     type Map_Type is private
--        with Aggregate =>  (Empty     => Empty_Map,
--                            Add_Named => Add_To_Map);
--     procedure Add_To_Map (M     : in out Map_Type;
--                           Key   : Integer;
--                           Value : String);
--     Empty_Map : constant Map_Type;
--     type Vector_Type is private
--        with Aggregate => (Empty          => Empty_Vector,
--                           Add_Unnamed    => Append_One,
--                           New_Indexed    => New_Vector,
--                           Assign_Indexed => Assign_Element);
--     function Empty_Vector (Capacity : Integer := 0) return Vector_Type;
--     procedure Append_One (V : in out Vector_Type; New_Item : String);
--     procedure Assign_Element (V     : in out Vector_Type;
--                               Index : Positive;
--                               Item  : String);
--     function New_Vector (First, Last : Positive) return Vector_Type
--        with Pre => (First = Positive'First);
-- end ARM_4_3_5;
--
package ARM_4_3_5 is
   --  Set_Type is a set-like container type.
   type Set_Type is private
      with Aggregate => (Empty       => Empty_Set,
                         Add_Unnamed => Include);
   function Empty_Set return Set_Type;

   subtype Small_Int is Integer range -1000..1000;

   procedure Include (S : in out Set_Type; N : in Small_Int);

   --  Map_Type is a map-like container type.
   type Map_Type is private
      with Aggregate =>  (Empty     => Empty_Map,
                          Add_Named => Add_To_Map);

   procedure Add_To_Map (M     : in out Map_Type;
                         Key   : in Integer;
                         Value : in String);

   Empty_Map : constant Map_Type;

   --  Vector_Type is an extensible array-like container type.
   type Vector_Type is private
      with Aggregate => (Empty          => Empty_Vector,
                         Add_Unnamed    => Append_One,
                         New_Indexed    => New_Vector,
                         Assign_Indexed => Assign_Element);

   function Empty_Vector (Capacity : Integer := 0) return Vector_Type;

   procedure Append_One (V : in out Vector_Type; New_Item : in String);

   procedure Assign_Element (V     : in out Vector_Type;
                             Index : in Positive;
                             Item  : in String);

   function New_Vector (First, Last : Positive) return Vector_Type
      with Pre => First = Positive'First;
      --  Vectors are always indexed starting at the
      --  lower bound of their index subtype.
-- Private part not shown.

end ARM_4_3_5;