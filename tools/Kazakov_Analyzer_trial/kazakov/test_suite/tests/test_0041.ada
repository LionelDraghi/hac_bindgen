--
-- ARM 4.2.1(19-24) User-Defined Literals
--
-- Success: 29:1..56:14 Tree *
--
-- procedure ARM_4_2_1 is
--    subtype Roman_Character is Wide_Wide_Character
--    with Static_Predicate =>
--       Roman_Character in 'I' | 'V' | 'X' | 'L' | 'C' | 'D' | 'M';
--    Max_Roman_Number : constant := 3999;
--    type Roman_Number is range 1..Max_Roman_Number
--       with String_Literal => To_Roman_Number;
--    function To_Roman_Number (S : Wide_Wide_String) return Roman_Number
--       with Pre => ((S'Length > 0) and then
--          (for all Char of S => Char in Roman_Character));
--    function To_Roman_Number (S : Wide_Wide_String) return Roman_Number is
--       ((declare
--          R : constant array (Integer range <>) of Roman_Number :=
--             (for D in S'Range => Roman_Digit'Enum_Rep
--                 (Roman_Digit'Wide_Wide_Value ((''' & S (D) & '''))));
--        begin
--          [for I in R'Range =>
--             ((if ((I < R'Last) and then (R (I) < R ((I + 1)))) then -(1) else 1) * R (I))]'Reduce ("+", 0)));
--    X : Roman_Number := ("III" * "IV" * "XII");
-- begin
--    null;
-- end ARM_4_2_1;
--
procedure ARM_4_2_1 is
   subtype Roman_Character is Wide_Wide_Character
   with Static_Predicate =>
      Roman_Character in 'I' | 'V' | 'X' | 'L' | 'C' | 'D' | 'M';

   Max_Roman_Number : constant := 3_999;  -- MMMCMXCIX

   type Roman_Number is range 1 .. Max_Roman_Number
      with String_Literal => To_Roman_Number;
   function To_Roman_Number (S : Wide_Wide_String) return Roman_Number
      with Pre => S'Length > 0 and then
         (for all Char of S => Char in Roman_Character);

   function To_Roman_Number (S : Wide_Wide_String) return Roman_Number is
      (declare
         R : constant array (Integer range <>) of Roman_Number :=
            (for D in S'Range => Roman_Digit'Enum_Rep
                (Roman_Digit'Wide_Wide_Value (''' & S(D) & ''')));
                        -- See 3.5.2 and 13.4
       begin
         [for I in R'Range =>
            (if I < R'Last and then R(I) < R(I + 1) then -1 else 1) * R(I)]
               'Reduce("+", 0)
      );
   X : Roman_Number := "III" * "IV" * "XII"; -- 144 (that is, CXLIV)
begin
   null;
end ARM_4_2_1;