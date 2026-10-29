--
-- ARM 9.4(20 i-k) Protected Units and Protected Objects
--
-- Success: 29:1..37:19, 39:1..55:19 Tree *
--
-- with Ada.Finalization.Controlled;
-- package Window_Manager is
--     type Root_Window is new Ada.Finalization.Controlled with private;
--     type Any_Window is access all Root_Window;
-- private
--     procedure Finalize (Object : in out Root_Window);
-- end Window_Manager;
-- 
-- package body Window_Manager is
--    protected type Lock is
--        entry Get_Lock;
--        procedure Free_Lock;
--    end Lock;
--    Window_Lock : Lock;
--    procedure Finalize (Object : in out Root_Window) is
--    begin
--        Window_Lock.Get_Lock;
--        Window_Lock.Free_Lock;
--    end Finalize;
--    A_Window : Any_Window := new (Root_Window);
-- end Window_Manager;
--
with Ada.Finalization.Controlled;
package Window_Manager is
    type Root_Window is new Ada.Finalization.Controlled with private;
    type Any_Window is access all Root_Window;

private

    procedure Finalize (Object : in out Root_Window);

end Window_Manager;

package body Window_Manager is
   protected type Lock is
       entry Get_Lock;
       procedure Free_Lock;
   end Lock;

   Window_Lock : Lock;

   procedure Finalize (Object : in out Root_Window) is
   begin
       Window_Lock.Get_Lock;

       Window_Lock.Free_Lock;
   end Finalize;

   A_Window : Any_Window := new Root_Window;
end Window_Manager;