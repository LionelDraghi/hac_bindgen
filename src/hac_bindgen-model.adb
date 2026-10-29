-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body Hac_Bindgen.Model is

   function Has_Text (Value : Text) return Boolean is
     (Ada.Strings.Unbounded.Length (Value) > 0);

   procedure Check_Location (Location : Source_Location) is
   begin
      if not Has_Text (Location.File_Path) then
         raise Model_Error with "source location has no file path";
      end if;
   end Check_Location;

   procedure Check_Type_Reference (Reference : Type_Reference) is
   begin
      if not Has_Text (Reference.Source_Name)
        or else not Has_Text (Reference.Canonical_Name)
      then
         raise Model_Error with "type reference has no name";
      end if;

      if Reference.Resolution = Unresolved
        and then not Reference.Subtype_Chain.Is_Empty
      then
         raise Model_Error with
           "unresolved type has subtype information; mark it partially resolved";
      elsif Reference.Resolution /= Unresolved
        and then Reference.Subtype_Chain.Is_Empty
      then
         raise Model_Error with "resolved type has no subtype chain";
      end if;

      for Identity of Reference.Subtype_Chain loop
         if not Has_Text (Identity.Source_Name)
           or else not Has_Text (Identity.Canonical_Name)
         then
            raise Model_Error with "subtype chain contains an unnamed identity";
         elsif Reference.Resolution = Resolved
           and then Identity.Kind = Unknown_Type
         then
            raise Model_Error with
              "resolved subtype chain contains an unknown type category";
         end if;
      end loop;
   end Check_Type_Reference;

   ---------------------------------------------------------------------

   procedure Validate_Model (Model : Package_Model) is
   begin
      if not Has_Text (Model.Source_Name)
        or else not Has_Text (Model.Canonical_Name)
      then
         raise Model_Error with "package model has no name";
      end if;

      Check_Location (Model.Location);

      for Declaration of Model.Declarations loop
         if not Has_Text (Declaration.Source_Name)
           or else not Has_Text (Declaration.Canonical_Name)
         then
            raise Model_Error with "public declaration has no name";
         end if;

         Check_Location (Declaration.Location);

         declare
            Repetitions : Natural := 0;
         begin
            for Other of Model.Declarations loop
               if Other.Id = Declaration.Id then
                  Repetitions := Repetitions + 1;
               end if;
            end loop;

            if Repetitions > 1 then
               raise Model_Error with "duplicate declaration identity";
            end if;
         end;

         if Declaration.Kind = Procedure_Declaration
           or else Declaration.Kind = Function_Declaration
         then
            for Item of Declaration.Parameters loop
               if not Has_Text (Item.Source_Name)
                 or else not Has_Text (Item.Canonical_Name)
               then
                  raise Model_Error with "parameter has no name";
               end if;

               Check_Location (Item.Location);
               Check_Type_Reference (Item.Parameter_Type);
            end loop;
         elsif not Declaration.Parameters.Is_Empty then
            raise Model_Error with
              "non-subprogram declaration has parameters";
         end if;

         case Declaration.Kind is
            when Function_Declaration =>
               Check_Type_Reference (Declaration.Result_Type);

            when Object_Declaration =>
               Check_Type_Reference (Declaration.Object_Type);

            when others =>
               null;
         end case;
      end loop;
   end Validate_Model;

   ---------------------------------------------------------------------

   procedure Validate_Analysis
     (Model  : Package_Model;
      Result : Analysis_Result)
   is
   begin
      Validate_Model (Model);

      for Item_Result of Result.Declarations loop
         declare
            Matches : Natural := 0;
         begin
            for Candidate of Model.Declarations loop
               if Candidate.Id = Item_Result.Declaration then
                  Matches := Matches + 1;
               end if;
            end loop;

            if Matches = 0 then
               raise Model_Error with
                 "analysis result refers to an unknown declaration";
            elsif Matches > 1 then
               raise Model_Error with
                 "analysis result refers to a duplicate declaration identity";
            end if;

            declare
               Repetitions : Natural := 0;
            begin
               for Candidate of Result.Declarations loop
                  if Candidate.Declaration = Item_Result.Declaration then
                     Repetitions := Repetitions + 1;
                  end if;
               end loop;

               if Repetitions > 1 then
                  raise Model_Error with
                    "declaration has multiple analysis results";
               end if;
            end;

            if Item_Result.Decision.Kind = Not_Bindable then
               if not Has_Text (Item_Result.Decision.Warning_Id)
                 or else not Has_Text (Item_Result.Decision.Reason)
               then
                  raise Model_Error with
                    "non-bindable declaration has no warning identifier or reason";
               end if;

               Check_Location (Item_Result.Decision.Location);
            end if;
         end;
      end loop;

      for Declaration of Model.Declarations loop
         declare
            Matches : Natural := 0;
         begin
            for Item_Result of Result.Declarations loop
               if Item_Result.Declaration = Declaration.Id then
                  Matches := Matches + 1;
               end if;
            end loop;

            if Matches = 0 then
               raise Model_Error with
                 "public declaration has no analysis result";
            elsif Matches > 1 then
               raise Model_Error with
                 "public declaration has multiple analysis results";
            end if;
         end;
      end loop;
   end Validate_Analysis;

end Hac_Bindgen.Model;
