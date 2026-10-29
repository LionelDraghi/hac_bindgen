--
-- ARM 9.6.1(2-14) Formatting, Time Zones, and other operations for Time
--
-- Success: 127:1..140:28, 142:1..163:28, 166:1..284:28 Tree *
--
-- package Ada.Calendar.Time_Zones 
--    with Nonblocking, Global => in out synchronized is
--    type Time_Offset is range -((28 * 60))..(28 * 60);
--    Unknown_Zone_Error : exception;
--    function Local_Time_Offset (Date : Time := Clock) return Time_Offset;
--    function UTC_Time_Offset (Date : Time := Clock) return Time_Offset
--       renames Local_Time_Offset;
-- end Ada.Calendar.Time_Zones;
--
-- package Ada.Calendar.Arithmetic 
--    with Nonblocking, Global => in out synchronized is
--    type Day_Count is range
--      -((366 * (1 + Year_Number'Last + 0-(Year_Number'First))))..(366 * (1 + Year_Number'Last + 0-(Year_Number'First)));
--    subtype Leap_Seconds_Count is Integer range -(2047)..2047;
--    procedure Difference (Left, Right : Time;
--                          Days : out Day_Count;
--                          Seconds : out Duration;
--                          Leap_Seconds : out Leap_Seconds_Count);
--    function "+" (Left : Time; Right : Day_Count) return Time;
--    function "+" (Left : Day_Count; Right : Time) return Time;
--    function "-" (Left : Time; Right : Day_Count) return Time;
--    function "-" (Left, Right : Time) return Day_Count;
-- end Ada.Calendar.Arithmetic;
--
-- with Ada.Calendar.Time_Zones;
-- package Ada.Calendar.Formatting 
--    with Nonblocking, Global => in out synchronized is
--    type Day_Name is (Monday, Tuesday, Wednesday, Thursday,
--        Friday, Saturday, Sunday);
--    function Day_of_Week (Date : Time) return Day_Name;
--    subtype Hour_Number         is Natural range 0..23;
--    subtype Minute_Number       is Natural range 0..59;
--    subtype Second_Number       is Natural range 0..59;
--    subtype Second_Duration     is Day_Duration range 0.0..1.0;
--    function Year       (Date : Time;
--                         Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Year_Number;
--    function Month      (Date : Time;
--                         Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Month_Number;
--    function Day        (Date : Time;
--                         Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Day_Number;
--    function Hour       (Date : Time;
--                         Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Hour_Number;
--    function Minute     (Date : Time;
--                         Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Minute_Number;
--    function Second     (Date : Time)
--                            return Second_Number;
--    function Sub_Second (Date : Time)
--                            return Second_Duration;
--    function Seconds_Of (Hour   :  Hour_Number;
--                         Minute : Minute_Number;
--                         Second : Second_Number := 0;
--                         Sub_Second : Second_Duration := 0.0)
--                            return Day_Duration;
--    procedure Split (Seconds    : Day_Duration;
--                     Hour       : out Hour_Number;
--                     Minute     : out Minute_Number;
--                     Second     : out Second_Number;
--                     Sub_Second : out Second_Duration);
--    function Time_Of (Year       : Year_Number;
--                      Month      : Month_Number;
--                      Day        : Day_Number;
--                      Hour       : Hour_Number;
--                      Minute     : Minute_Number;
--                      Second     : Second_Number;
--                      Sub_Second : Second_Duration := 0.0;
--                      Leap_Second : Boolean := False;
--                      Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Time;
--    function Time_Of (Year       : Year_Number;
--                      Month      : Month_Number;
--                      Day        : Day_Number;
--                      Seconds    : Day_Duration := 0.0;
--                      Leap_Second : Boolean := False;
--                      Time_Zone  : Time_Zones.Time_Offset := 0)
--                            return Time;
--    procedure Split (Date       : Time;
--                     Year       : out Year_Number;
--                     Month      : out Month_Number;
--                     Day        : out Day_Number;
--                     Hour       : out Hour_Number;
--                     Minute     : out Minute_Number;
--                     Second     : out Second_Number;
--                     Sub_Second : out Second_Duration;
--                     Time_Zone  : Time_Zones.Time_Offset := 0);
--    procedure Split (Date       : Time;
--                     Year       : out Year_Number;
--                     Month      : out Month_Number;
--                     Day        : out Day_Number;
--                     Hour       : out Hour_Number;
--                     Minute     : out Minute_Number;
--                     Second     : out Second_Number;
--                     Sub_Second : out Second_Duration;
--                     Leap_Second : out Boolean;
--                     Time_Zone  : Time_Zones.Time_Offset := 0);
--    procedure Split (Date       : Time;
--                     Year       : out Year_Number;
--                     Month      : out Month_Number;
--                     Day        : out Day_Number;
--                     Seconds    : out Day_Duration;
--                     Leap_Second : out Boolean;
--                     Time_Zone  : Time_Zones.Time_Offset := 0);
--    function Image (Date : Time;
--                    Include_Time_Fraction : Boolean := False;
--                    Time_Zone  : Time_Zones.Time_Offset := 0) return String;
--    function Local_Image (Date : Time;
--                          Include_Time_Fraction : Boolean := False)
--       return String is
--       (Image (Date, Include_Time_Fraction,
--               Time_Zones.Local_Time_Offset (Date)));
--    function Value (Date : String;
--                    Time_Zone  : Time_Zones.Time_Offset := 0) return Time;
--    function Image (Elapsed_Time : Duration;
--                    Include_Time_Fraction : Boolean := False) return String;
--    function Value (Elapsed_Time : String) return Duration;
-- end Ada.Calendar.Formatting;
--
package Ada.Calendar.Time_Zones 
   with Nonblocking, Global => in out synchronized is

   -- Time zone manipulation:

   type Time_Offset is range -28*60 .. 28*60;

   Unknown_Zone_Error : exception;

   function Local_Time_Offset (Date : Time := Clock) return Time_Offset;
   function UTC_Time_Offset (Date : Time := Clock) return Time_Offset
      renames Local_Time_Offset;

end Ada.Calendar.Time_Zones;

package Ada.Calendar.Arithmetic 
   with Nonblocking, Global => in out synchronized is
   -- Arithmetic on days:

   type Day_Count is range
     -366*(1+Year_Number'Last - Year_Number'First)
     ..
     366*(1+Year_Number'Last - Year_Number'First);

   subtype Leap_Seconds_Count is Integer range -2047 .. 2047;

   procedure Difference (Left, Right : in Time;
                         Days : out Day_Count;
                         Seconds : out Duration;
                         Leap_Seconds : out Leap_Seconds_Count);

   function "+" (Left : Time; Right : Day_Count) return Time;
   function "+" (Left : Day_Count; Right : Time) return Time;
   function "-" (Left : Time; Right : Day_Count) return Time;
   function "-" (Left, Right : Time) return Day_Count;

end Ada.Calendar.Arithmetic;

with Ada.Calendar.Time_Zones;
package Ada.Calendar.Formatting 
   with Nonblocking, Global => in out synchronized is
   -- Day of the week:
   type Day_Name is (Monday, Tuesday, Wednesday, Thursday,
       Friday, Saturday, Sunday);

   function Day_of_Week (Date : Time) return Day_Name;

   -- Hours:Minutes:Seconds access:
   subtype Hour_Number         is Natural range 0 .. 23;
   subtype Minute_Number       is Natural range 0 .. 59;
   subtype Second_Number       is Natural range 0 .. 59;
   subtype Second_Duration     is Day_Duration range 0.0 .. 1.0;

   function Year       (Date : Time;
                        Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Year_Number;

   function Month      (Date : Time;
                        Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Month_Number;
   function Day        (Date : Time;
                        Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Day_Number;

   function Hour       (Date : Time;
                        Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Hour_Number;

   function Minute     (Date : Time;
                        Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Minute_Number;

   function Second     (Date : Time)
                           return Second_Number;

   function Sub_Second (Date : Time)
                           return Second_Duration;

   function Seconds_Of (Hour   :  Hour_Number;
                        Minute : Minute_Number;
                        Second : Second_Number := 0;
                        Sub_Second : Second_Duration := 0.0)
                           return Day_Duration;

   procedure Split (Seconds    : in Day_Duration;
                    Hour       : out Hour_Number;
                    Minute     : out Minute_Number;
                    Second     : out Second_Number;
                    Sub_Second : out Second_Duration);

   function Time_Of (Year       : Year_Number;
                     Month      : Month_Number;
                     Day        : Day_Number;
                     Hour       : Hour_Number;
                     Minute     : Minute_Number;
                     Second     : Second_Number;
                     Sub_Second : Second_Duration := 0.0;
                     Leap_Second: Boolean := False;
                     Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Time;

   function Time_Of (Year       : Year_Number;
                     Month      : Month_Number;
                     Day        : Day_Number;
                     Seconds    : Day_Duration := 0.0;
                     Leap_Second: Boolean := False;
                     Time_Zone  : Time_Zones.Time_Offset := 0)
                           return Time;

   procedure Split (Date       : in Time;
                    Year       : out Year_Number;
                    Month      : out Month_Number;
                    Day        : out Day_Number;
                    Hour       : out Hour_Number;
                    Minute     : out Minute_Number;
                    Second     : out Second_Number;
                    Sub_Second : out Second_Duration;
                    Time_Zone  : in Time_Zones.Time_Offset := 0);

   procedure Split (Date       : in Time;
                    Year       : out Year_Number;
                    Month      : out Month_Number;
                    Day        : out Day_Number;
                    Hour       : out Hour_Number;
                    Minute     : out Minute_Number;
                    Second     : out Second_Number;
                    Sub_Second : out Second_Duration;
                    Leap_Second: out Boolean;
                    Time_Zone  : in Time_Zones.Time_Offset := 0);

   procedure Split (Date       : in Time;
                    Year       : out Year_Number;
                    Month      : out Month_Number;
                    Day        : out Day_Number;
                    Seconds    : out Day_Duration;
                    Leap_Second: out Boolean;
                    Time_Zone  : in Time_Zones.Time_Offset := 0);

   -- Simple image and value:
   function Image (Date : Time;
                   Include_Time_Fraction : Boolean := False;
                   Time_Zone  : Time_Zones.Time_Offset := 0) return String;

   function Local_Image (Date : Time;
                         Include_Time_Fraction : Boolean := False)
      return String is
      (Image (Date, Include_Time_Fraction,
              Time_Zones.Local_Time_Offset (Date)));

   function Value (Date : String;
                   Time_Zone  : Time_Zones.Time_Offset := 0) return Time;

   function Image (Elapsed_Time : Duration;
                   Include_Time_Fraction : Boolean := False) return String;

   function Value (Elapsed_Time : String) return Duration;

end Ada.Calendar.Formatting;