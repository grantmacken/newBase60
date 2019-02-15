xquery version "3.1";
module namespace newBase60  = "http://markup.nz/#newBase60";
(:~
: The <b>newBase60</b> library provides function for handling 
: dates and times to and from 'New Base 60' aka newBase60
: 
: based on a date-time stamp as xs:dateTime
: 1. Date: year-month-day will convert to and from 3 chars
: 2. Time: hours:minutes:seconds will convert to and from 3 chars
: 
: the newBase60 conversion can be used to name and archive documents.
: This would be suitable for archiving blog posts.
: A simple wait/sleep could be used the prevent duplicates, 
: if more than one post per second
: 
:)

(:~
show what lib can do in example
:)
declare
function newBase60:example() as xs:string*{
 let $nl := "&#10;"
 let $dateTime := current-dateTime() => adjust-dateTime-to-timezone(xs:dayTimeDuration('PT13H'))
 let $iDate := $dateTime => newBase60:dateToInteger()
 let $bDate :=  $dateTime => newBase60:dateToInteger() => newBase60:encode()
 let $bDateDecoded :=  $bDate =>  newBase60:decode()
 let $dtDate :=  $bDate =>  newBase60:decode() => newBase60:integerToDate()
 let $iTime := $dateTime => newBase60:timeToInteger()
 let $bTime := $dateTime => newBase60:timeToInteger() =>  newBase60:encode()
 let $bTimeDecoded :=  $bTime =>  newBase60:decode()
 let $dtTime := $bTime  =>  newBase60:decode() => newBase60:integerToTime()
 let $dtStamp := concat( string($bDate) , string($bTime) )
 return
  (
  ' - local current dateTime: ' || string($dateTime) ,$nl,
  ' - current date  : [ ' ||  string($dateTime cast as xs:date )|| ' ] ',$nl,
  ' - from date to integer:  [' || string($iDate) || ' ] ' ,$nl,
  ' - from integer to base60:[ ' ||  string($bDate)|| ' ] ',$nl,
  ' - from base60 to integer:[ ' ||  string($bDateDecoded)|| ' ] ',$nl,
  ' - from integer to date : [ ' ||  string($dtDate)|| ' ] ',$nl,
  ' - - - - - - - - - - - - - - - - - - - - - - - - ',$nl,
  ' - current time  : [ ' ||  string($dateTime cast as xs:time )|| ' ] ',$nl,
  ' - from time to integer: [' || string($iTime) || ' ] ' ,$nl,
  ' - from integer to base60:[ ' ||  string($bTime) || ' ] ',$nl,
  ' - from base60 to integer:[ ' ||  string($bTimeDecoded)|| ' ] ',$nl,
  ' - from integer to time : [ ' ||  string($dtTime)|| ' ] ',$nl,
  ' - - - - - - - - - - - - - - - - - - - - - - - - ',$nl,
  ' - 6 char date-time stamp: [ ' ||  string($dtStamp) || ' ] ',$nl,
  $nl
  )
};

declare
function newBase60:getFullYear(){
  xs:date(current-dateTime()) => year-from-date()
};

declare
function newBase60:getFullYear( $dateTime as xs:dateTime ){
 xs:date($dateTime) => year-from-date()
};

(:~
convert dateTime converted to an integer consisting of
a short date year + ordinal days in year
@param $dateTime xs:dateTime
@return represents a short date year + ordinal days in year
:)
declare
function newBase60:dateToInteger( $dateTime as xs:dateTime) as xs:integer{
try {
let $date := $dateTime cast as xs:date
  return (
  format-date(xs:date($date),"[Y01][d]") cast as xs:integer
  )
  } catch * {
    util:log-system-out(   'ERR:' || $err:code || ': '  || $err:description)
   }
};


(:~
convert dateTime to integer representing time as 
number of seconds from days start
@param $dateTime as xs:dateTime
@return xs:integer representing time as seconds from days start
:)
declare
function newBase60:timeToInteger( $dateTime as xs:dateTime) as xs:integer{
let $time := $dateTime cast as xs:time
let $hours :=    hours-from-dateTime($dateTime)
let $minutes :=  minutes-from-dateTime($dateTime)
let $seconds :=  floor(seconds-from-dateTime($dateTime))
let $totSecs := (xs:integer($hours) * 60 * 60) + (xs:integer($minutes) * 60) + xs:integer($seconds) 
return
xs:integer((xs:integer($hours) * 60 * 60) + (xs:integer($minutes) * 60) + xs:integer($seconds))
};

(:~
from a time or date represented as an integer encode as a base60 string
@param $n as xs:integer
@return a base60 encoded string 
:)
declare
function newBase60:encode($n as xs:integer) as xs:string {
let $seq1 := (0 to 9)
let $seq2 := map(function($x) { codepoints-to-string($x) }, string-to-codepoints('A') to string-to-codepoints('H'))
let $seq3 := map(function($x) { codepoints-to-string($x) }, string-to-codepoints('J') to string-to-codepoints('N'))
let $seq4 := map(function($x) { codepoints-to-string($x) }, string-to-codepoints('P') to string-to-codepoints('Z'))
let $seq5 := ('_')
let $seq6 := map(function($x) { codepoints-to-string($x) }, string-to-codepoints('a') to string-to-codepoints('k'))
let $seq7 := map(function($x) { codepoints-to-string($x) }, string-to-codepoints('m') to string-to-codepoints('z'))
let $seqChars := ($seq1, $seq2, $seq3, $seq4, $seq5 , $seq6, $seq7)
let $base := count($seqChars)
let $getRemainder := function($n){($n mod xs:integer($base))}
let $getChar := function($n){$seqChars[xs:integer($getRemainder($n) + 1)]}
let $nextN   := function($n){ ($n - xs:integer($getRemainder($n))) div xs:integer($base)}
let $getChar := function($n){$seqChars[xs:integer($getRemainder($n) + 1)]}
let $nextN   := function($n){ ($n - xs:integer($getRemainder($n))) div xs:integer($base)}
let $seqNth  := ( xs:integer($nextN($nextN($n))), xs:integer($nextN($n)) , xs:integer($n) )
return
(
string-join(map(function($n){$getChar($n)}, $seqNth),'')
)
};

(:~
from a newBase60 decode into a time or date represented as an integer
@param $nb60 as xs:string encoded date or time
@return decoded a time or date represented as an integer
:)
declare 
function newBase60:decode($nb60 as xs:string ) as xs:integer{
  let $base := 60
(:  The entry point is  $strB60 :)
  let $seqDecode :=
  map(function( $codePoint ){
   let $c := xs:integer($codePoint)
   return
           if ($c >= 48 and $c <= 57 ) then ($c - 48)
     else if ($c >= 65 and $c <= 72 ) then ($c - 55)
     else if ($c eq 73 or $c eq 108 ) then (1)
     else if ($c >= 74 and $c <= 78 ) then ($c - 56)
     else if ($c eq 79 ) then (0)
     else if ($c >= 80 and $c <= 90 ) then ($c - 57)
     else if ($c eq 95 ) then (34)
     else if ($c >= 97 and $c <= 107 ) then ($c - 62)
     else if ($c >= 109 and $c <= 122 ) then ($c - 63)
     else(0)
     },
     (map(function($ch){string-to-codepoints($ch)}, (for $ch in string-to-codepoints($nb60)
    return codepoints-to-string($ch)))
     ))
  let $tot := function($n2, $c){xs:integer(($base * $n2) + $c )}
  let $n2 := 0
  let $dc1 := $tot($n2, $seqDecode[1])
  let $dc2 := $tot($dc1, $seqDecode[2])
  let $decoded := $tot($dc2, $seqDecode[3])
  return
   $tot($dc2, $seqDecode[3])
};

(:~
convert a decoded short date integer into xs:date
@param  $decoded as xs:integer
@return a xs:date [yyyy-mm-dd]
:)
declare
function newBase60:integerToDate( $decoded as xs:integer ) as xs:date {
  let $yr := '20' || substring($decoded, 1, 2)
  let $yrStart := xs:date($yr || string('-01-01'))
  let $dysInYr := substring($decoded, 3, 5)
  let $duration := xs:dayTimeDuration("P" || string(xs:integer($dysInYr)- 1)  || "D")
  let $decodedDate := xs:date($yrStart + $duration)
  let $formatedDate := format-date($decodedDate, "[Y0001]-[M01]-[D01]", 'en', (), ())
  return
  xs:date($yrStart + $duration)
};

(:~
convert a decoded time integer into xs:time
@param  $decoded as xs:integer
@return a xs:time [hh-mm-ss]
:)
declare
function newBase60:integerToTime( $decoded as xs:integer) as xs:time{
  try {
  let $log := util:log-system-out('INFO:' || $decoded  )
  let $duration := xs:dayTimeDuration("PT" || string(xs:integer($decoded))  || "S")
  let $log := util:log-system-out('INFO:' || $duration  )
  let $tStart := xs:time(string('00:00:00'))
  return
  xs:time($tStart + $duration)
  } catch * {
    util:log-system-out(   'ERR:' || $err:code || ': '  || $err:description)
   }
 };
