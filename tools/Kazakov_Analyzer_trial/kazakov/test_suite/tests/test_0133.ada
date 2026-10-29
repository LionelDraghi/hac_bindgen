--
-- ARM 11.4.1 The Package Exceptions
--
-- Success: 49:1..99:19 Tree *
--
-- with Ada.Streams;
-- package Ada.Exceptions
--     with Preelaborate, Nonblocking, Global => in out synchronized is
--     type Exception_Id is private
--         with Preelaborable_Initialization;
--     Null_Id : constant Exception_Id;
--     function Exception_Name (Id : Exception_Id) return String;
--     function Wide_Exception_Name (Id : Exception_Id) return Wide_String;
--     function Wide_Wide_Exception_Name (Id : Exception_Id)
--         return Wide_Wide_String;
--     type Exception_Occurrence is limited private
--         with Preelaborable_Initialization;
--     type Exception_Occurrence_Access is access all Exception_Occurrence;
--     Null_Occurrence : constant Exception_Occurrence;
--     procedure Raise_Exception (E : Exception_Id;
--                               Message : String := "")
--         with No_Return;
--     function Exception_Message (X : Exception_Occurrence) return String;
--     procedure Reraise_Occurrence (X : Exception_Occurrence);
--     function Exception_Identity (X : Exception_Occurrence)
--                                 return Exception_Id;
--     function Exception_Name (X : Exception_Occurrence) return String;
--     function Wide_Exception_Name (X : Exception_Occurrence)
--         return Wide_String;
--     function Wide_Wide_Exception_Name (X : Exception_Occurrence)
--         return Wide_Wide_String;
--     function Exception_Information (X : Exception_Occurrence) return String;
--     procedure Save_Occurrence (Target : out Exception_Occurrence;
--                               Source : Exception_Occurrence);
--     function Save_Occurrence (Source : Exception_Occurrence)
--                              return Exception_Occurrence_Access;
--     procedure Read_Exception_Occurrence
--        (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
--         Item   : out Exception_Occurrence);
--     procedure Write_Exception_Occurrence
--        (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
--         Item   : Exception_Occurrence);
--     for Exception_Occurrence'Read use Read_Exception_Occurrence;
--     for Exception_Occurrence'Write use Write_Exception_Occurrence;
-- private
-- end Ada.Exceptions;
--
with Ada.Streams;
package Ada.Exceptions
    with Preelaborate, Nonblocking, Global => in out synchronized is
    type Exception_Id is private
        with Preelaborable_Initialization;
    Null_Id : constant Exception_Id;
    function Exception_Name(Id : Exception_Id) return String;
    function Wide_Exception_Name(Id : Exception_Id) return Wide_String;
    function Wide_Wide_Exception_Name(Id : Exception_Id)
        return Wide_Wide_String;

    type Exception_Occurrence is limited private
        with Preelaborable_Initialization;
    type Exception_Occurrence_Access is access all Exception_Occurrence;
    Null_Occurrence : constant Exception_Occurrence;

    procedure Raise_Exception(E : in Exception_Id;
                              Message : in String := "")
        with No_Return;
    function Exception_Message(X : Exception_Occurrence) return String;
    procedure Reraise_Occurrence(X : in Exception_Occurrence);

    function Exception_Identity(X : Exception_Occurrence)
                                return Exception_Id;
    function Exception_Name(X : Exception_Occurrence) return String;
        -- Same as Exception_Name(Exception_Identity(X)).
    function Wide_Exception_Name(X : Exception_Occurrence)
        return Wide_String;
        -- Same as Wide_Exception_Name(Exception_Identity(X)).
    function Wide_Wide_Exception_Name(X : Exception_Occurrence)
        return Wide_Wide_String;
        -- Same as Wide_Wide_Exception_Name(Exception_Identity(X)).
    function Exception_Information(X : Exception_Occurrence) return String;

    procedure Save_Occurrence(Target : out Exception_Occurrence;
                              Source : in Exception_Occurrence);
    function Save_Occurrence(Source : Exception_Occurrence)
                             return Exception_Occurrence_Access;

    procedure Read_Exception_Occurrence
       (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
        Item   : out Exception_Occurrence);
    procedure Write_Exception_Occurrence
       (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
        Item   : in Exception_Occurrence);

    for Exception_Occurrence'Read use Read_Exception_Occurrence;
    for Exception_Occurrence'Write use Write_Exception_Occurrence;

private
   -- not specified by the language
end Ada.Exceptions;