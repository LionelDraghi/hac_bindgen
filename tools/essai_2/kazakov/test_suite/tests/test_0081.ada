--
-- ARM 7.3.1(16-17) Private Operations
--
-- Success: 19:1..31:16 Tree *
--
-- package body Key_Manager is
--    Last_Key : Key := Null_Key;
--    procedure Get_Key (K : out Key) is
--    begin
--       Last_Key := (Last_Key + 1);
--       K := Last_Key;
--    end Get_Key;
--    function "<" (X, Y : Key) return Boolean is
--    begin
--       return (Natural (X) < Natural (Y));
--    end "<";
-- end Key_Manager;
--
package body Key_Manager is
   Last_Key : Key := Null_Key;
   procedure Get_Key(K : out Key) is
   begin
      Last_Key := Last_Key + 1;
      K := Last_Key;
   end Get_Key;

   function "<" (X, Y : Key) return Boolean is
   begin
      return Natural(X) < Natural(Y);
   end "<";
end Key_Manager;