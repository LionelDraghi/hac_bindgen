--
-- ARM 7.6 Assignment and Finalization
--
-- Success: 20:1..37:21 Tree *
--
-- package Ada.Finalization
--     with Pure, Nonblocking => False is
--     type Controlled is abstract tagged private
--        with Preelaborable_Initialization;
--     procedure Initialize (Object : in out Controlled) is null;
--     procedure Adjust     (Object : in out Controlled) is null;
--     procedure Finalize   (Object : in out Controlled) is null;
--     type Limited_Controlled is abstract tagged limited private
--        with Preelaborable_Initialization;
--     procedure Initialize (Object : in out Limited_Controlled) is null;
--     procedure Finalize   (Object : in out Limited_Controlled) is null;
-- private
-- end Ada.Finalization;
--
package Ada.Finalization
    with Pure, Nonblocking => False is

    type Controlled is abstract tagged private
       with Preelaborable_Initialization;

    procedure Initialize (Object : in out Controlled) is null;
    procedure Adjust     (Object : in out Controlled) is null;
    procedure Finalize   (Object : in out Controlled) is null;

    type Limited_Controlled is abstract tagged limited private
       with Preelaborable_Initialization;

    procedure Initialize (Object : in out Limited_Controlled) is null;
    procedure Finalize   (Object : in out Limited_Controlled) is null;
private
    -- not specified by the language
end Ada.Finalization;