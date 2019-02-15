xquery version '3.1';
(:~
This  module contains XQSuite tests for library
http://markup.nz/#newBase60
@see ../content/newBase60.xqm

The new Base 60 numbering system was designed for URL shortening
with a limited easy to read character set.
For further info read
@see ../README.md

@see http://tantek.pbworks.com/w/page/19402946/NewBase60
to check integer to newBase60 conversion paste newBase60 char set
0123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz
into form at site below
@see https://jalu.ch/coding/base_converter.php

@author grantmacken@gmail.com
@version 0.0.1

Notes: Tests 
Tests try to follow BDD style

Given a precondition
When a thing happens
Then a result should be observable
:)

module namespace t-newBase60 = "http://markup.nz/#t-newBase60";
import module namespace newBase60 = "http://markup.nz/#newBase60";
import module namespace test = "http://exist-db.org/xquery/xqsuite"
  at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

(:~
newBase60:dateToInteger#1 test 1
@Given first day of year as an iso date-time '2019-01-01T00:00:00'' as typed xs:dateTime
@When converted into a short short integer date (short date year + ordinal days in years)
@Then '18339' is the correct short integer date
:)
declare
%test:name(
"
should convert first day of year 2019 to integer 18339
"
)
%test:args('2019-01-01T00:00:00')
%test:assertEquals(191)
function t-newBase60:convertFirstDayOfYearToShortDateInteger($arg){
xs:dateTime($arg) => newBase60:dateToInteger()
};

(:~
newBase60:timeToInteger#1 test 1
@Given last second of the day as an iso date-time '2018-12-05T23:59:59' as typed xs:dateTime
@When converted into seconds from days start
@Then '86399' is the correct number of seconds from days start
:)
declare
%test:name(
"
should convert in time in last second of the day to integer 86399
"
)
%test:args('2018-12-05T23:59:59')
%test:assertEquals(86399)
function t-newBase60:convertLastSecondOfDayToSecondsFromDaysStartInteger($arg){
(:  arrange        =>    action        :)
 xs:dateTime($arg) => newBase60:timeToInteger()
};



(:~
newBase60:encode#1 test 1
@Given a first day of the year date-time '2018-12-05T23:59:59' as typed xs:dateTime
@When converted into seconds from days start and newBase60 encoded
@Then '03B' is the correct encoded newBase60 date
:)
declare
%test:name(
"
should convert dateTime to newBase60 encoded date 03B
"
)
%test:args('2019-01-01T23:59:59')
%test:assertEquals('03B')
function t-newBase60:encodeFirstDayOfYearAsBase60Date($arg){
xs:dateTime($arg) => newBase60:dateToInteger() => newBase60:encode()
};

(:~
newBase60:encode#1 test 2
@Given last second of day '2018-12-05T23:59:59' as typed xs:dateTime
@When converted into seconds from days start and newBase60 encoded
@Then 'Pzz' is the correct encoded newBase60 time
:)
declare
%test:name(
"
should convert dateTime to newBase60 time
"
)
%test:args('2019-01-01T23:59:59')
%test:assertEquals('Pzz')
function t-newBase60:encodeLastSecondOfDayAsBase60Time($arg){
xs:dateTime($arg) => newBase60:timeToInteger() => newBase60:encode()
};


(:~
newBase60:decode#1 test 1
@Given an encoded newBase60 date '03B' as a typed xs:string
@When decoded to a short date integer
@Then '191' is the correct date integer
:)
declare
%test:name(
"
should decode newBase60 to short date integer
"
)
%test:args('03B')
%test:assertEquals(191)
function t-newBase60:decodeBase60EncodedFirstDayOfYear($arg){
(: arrange  =>    action :)
xs:string($arg) => newBase60:decode() 
};

(:~
newBase60:integerToDate#1 test 1
@Given an encoded newBase60 date '03B' as a typed xs:string
@When decoded and converted to a date
@Then 2019-01-01 is the correct date
:)
declare
%test:name(
"
should convert newBase60 to date"
)
%test:args('03B')
%test:assertEquals( '2019-01-01' )
function t-newBase60:dateFromBase60EncodedFirstDayOfYear($arg){
(: arrange  =>                      action :)
$arg => newBase60:decode()  => newBase60:integerToDate()
};

(:~
newBase60:integerToDate#1  test 1
@Given an  encoded newBase60 date '03B' as a typed xs:string 
@When decoded and converted to a date
@Then '2019-01-01' is the correct date
:)
declare
%test:name(
"
should convert newBase60 to date"
)
%test:args('03B')
%test:assertEquals( '2019-01-01' )
function t-newBase60:getDateFromBase60EncodedFirstDayOfYear($arg){
(: arrange  =>                      action :)
$arg => newBase60:decode()  => newBase60:integerToDate()
};

(:~
newBase60:integerToDate()
newBase60:decode#1 test 4
@Given a newBase60 encoded time 'Pzz' as a xs:string
@When decoded the converted to a time
@Then '23:59:59' is the correct time
:)
declare
%test:name(
"
should convert newBase60 to time"
)
%test:args('Pzz')
%test:assertEquals( '23:59:59' )
function t-newBase60:getTimeFromBase60EncodedLastSecondOfDay($arg){
(: arrange  =>                      action :)
$arg => newBase60:decode()  => newBase60:integerToTime()
};







