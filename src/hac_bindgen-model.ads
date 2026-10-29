-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
--
--  Parser-independent representation of a package's public API.
-- -----------------------------------------------------------------------------

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Hac_Bindgen.Model is

   subtype Text is Ada.Strings.Unbounded.Unbounded_String;

   type Declaration_Id is new Positive;

   type Source_Location is record
      File_Path : Text;
      Line      : Positive;
      Column    : Positive;
   end record;

   type Type_Kind is
     (Unknown_Type,
      Integer_Type,
      Floating_Point_Type,
      Boolean_Type,
      Enumeration_Type,
      String_Type,
      Fixed_Point_Type,
      Modular_Type,
      Access_Type,
      Array_Type,
      Record_Type,
      Private_Type,
      Task_Type,
      Protected_Type,
      Other_Type);

   type Resolution_State is (Unresolved, Partially_Resolved, Resolved);

   type Type_Identity is record
      Source_Name    : Text;
      Canonical_Name : Text;
      Kind           : Type_Kind := Unknown_Type;
   end record;

   package Type_Identity_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Type_Identity);

   type Type_Reference is record
      Source_Name    : Text;
      Canonical_Name : Text;
      Resolution     : Resolution_State := Unresolved;
      Subtype_Chain  : Type_Identity_Vectors.Vector;
   end record;

   type Parameter_Mode is (In_Mode, Out_Mode, In_Out_Mode);

   type Parameter is record
      Source_Name    : Text;
      Canonical_Name : Text;
      Mode           : Parameter_Mode := In_Mode;
      Parameter_Type : Type_Reference;
      Location       : Source_Location;
   end record;

   package Parameter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Parameter);

   type Declaration_Kind is
     (Procedure_Declaration,
      Function_Declaration,
      Type_Declaration,
      Object_Declaration,
      Exception_Declaration,
      Package_Declaration,
      Renaming_Declaration,
      Generic_Declaration,
      Other_Declaration);

   type Public_Declaration (Kind : Declaration_Kind := Other_Declaration) is
   record
      Id             : Declaration_Id;
      Source_Name    : Text;
      Canonical_Name : Text;
      Location       : Source_Location;
      Parameters     : Parameter_Vectors.Vector;
      case Kind is
         when Function_Declaration =>
            Result_Type : Type_Reference;
         when Object_Declaration =>
            Object_Type : Type_Reference;
         when Type_Declaration =>
            Declared_Kind : Type_Kind := Unknown_Type;
         when others =>
            null;
      end case;
   end record;

   package Declaration_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Public_Declaration);

   type Package_Model is record
      Source_Name    : Text;
      Canonical_Name : Text;
      Location       : Source_Location;
      Declarations   : Declaration_Vectors.Vector;
   end record;

   type Classification_Kind is (Bindable, Not_Bindable);

   type Classification (Kind : Classification_Kind := Bindable) is record
      case Kind is
         when Bindable =>
            null;
         when Not_Bindable =>
            Warning_Id : Text;
            Reason     : Text;
            Location   : Source_Location;
      end case;
   end record;

   type Declaration_Result is record
      Declaration : Declaration_Id;
      Decision    : Classification;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Declaration_Result);

   type Analysis_Result is record
      Declarations : Result_Vectors.Vector;
   end record;

   Model_Error : exception;

   procedure Validate_Model (Model : Package_Model);

   procedure Validate_Analysis
     (Model  : Package_Model;
      Result : Analysis_Result);

end Hac_Bindgen.Model;
