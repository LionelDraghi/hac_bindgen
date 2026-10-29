--
-- ARM 9.1 Task Units and Task Objects
--
-- Success: 31:1..60:12 Tree *
--
-- package ARM_9_1 is
--    task type Server is
--       entry Next_Work_Item (WI : Work_Item);
--       entry Shut_Down;
--    end Server;
--    task type Keyboard_Driver (ID : Keyboard_ID := New_ID) is
--          new Serial_Device with
--       entry Read (C : out Character);
--       entry Write (C : Character);
--    end Keyboard_Driver;
--    task Controller is
--       entry Request (Level) (D : Item);
--    end Controller;
--    task Parser is
--       entry Next_Lexeme (L : Lexical_Element);
--       entry Next_Action (A : out Parser_Action);
--    end Parser;
--    task User;
--    Agent    : Server;
--    Teletype : Keyboard_Driver (TTY_ID);
--    Pool     : array (1..10) of Keyboard_Driver;
--    type Keyboard is access Keyboard_Driver;
--    Terminal : Keyboard := new (Keyboard_Driver (Term_ID));
-- end ARM_9_1;
--
package ARM_9_1 is
   task type Server is
      entry Next_Work_Item(WI : in Work_Item);
      entry Shut_Down;
   end Server;

   task type Keyboard_Driver(ID : Keyboard_ID := New_ID) is
         new Serial_Device with  -- see 3.9.4
      entry Read (C : out Character);
      entry Write(C : in  Character);
   end Keyboard_Driver;

   task Controller is
      entry Request(Level)(D : Item);  --  a family of entries
   end Controller;

   task Parser is
      entry Next_Lexeme(L : in  Lexical_Element);
      entry Next_Action(A : out Parser_Action);
   end;

   task User;  --  has no entries

   Agent    : Server;
   Teletype : Keyboard_Driver(TTY_ID);
   Pool     : array(1 .. 10) of Keyboard_Driver;

   type Keyboard is access Keyboard_Driver;
   Terminal : Keyboard := new Keyboard_Driver(Term_ID);
end ARM_9_1;