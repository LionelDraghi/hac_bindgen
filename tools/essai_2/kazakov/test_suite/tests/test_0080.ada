--
-- ARM 7.3.1(15) Private Operations
--
-- Success: 16:1..24:16 Tree *
--
-- package Key_Manager is
--    type Key is private;
--    Null_Key : constant Key;
--    procedure Get_Key (K : out Key);
--    function "<" (X, Y : Key) return Boolean;
-- private
--    type Key is new Natural;
--    Null_Key : constant Key := Key'First;
-- end Key_Manager;
--
package Key_Manager is
   type Key is private;
   Null_Key : constant Key; -- a deferred constant declaration (see 7.4)
   procedure Get_Key(K : out Key);
   function "<" (X, Y : Key) return Boolean;
private
   type Key is new Natural;
   Null_Key : constant Key := Key'First;
end Key_Manager;