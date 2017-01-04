# encoding: UTF-8
#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'vformat/icalendar'
require 'vformat/zoneinfo'
require 'vformat/vcard'
require 'test/unit'
include VFormat

class Test::Unit::TestCase
    def comp_sort(c)
	return comp_sort_a(c.gsub("\r", "").split("\n")).map{|x| x.gsub(/^\s+/, "\t")}.join("\n")
    end
    def comp_sort_a(c1)
	c2 = []
	c2_sub_comps = []
	sub_comp = nil
	c1.each do |i|
	    if sub_comp
		if i == "END:#{sub_comp[:name]}"
		    c2_sub_comps << sub_comp
		    sub_comp = nil
                    next
		end
	        sub_comp[:body] << i
		next
	    end
	    if i =~ /^BEGIN:(.*)/
		sub_comp = {:name => $1, :body => []}
		next
	    end
	    if i =~ /^\s/
		c2[-1] += "\n" + i
		next
	    end
	    c2 << i
	end
	ret = c2.sort
	c2_sub_comps.sort{|a,b| a[:name] <=> b[:name]}.each do |s|
	    ret += ["BEGIN:#{s[:name]}"] + comp_sort_a(s[:body]) + ["END:#{s[:name]}"]
	end
	return ret
    end
    def assert_equal_comps(premiss, result)
        premiss = comp_sort(premiss)
        result =  comp_sort(result)
        def result.inspect
            self
        end
        def premiss.inspect
            self
        end
        assert_equal(premiss, result)
    end
    def assert_equal_encoded(premiss, result)
        premiss = premiss.gsub(/\r?\n/, "\r\n")

        def result.inspect
            self
        end
        def premiss.inspect
            self
        end

        assert_equal(premiss, result)
    end

    def cmp_component_attributes(c1_arr, c2_arr)
        assert_equal(c1_arr.size, c2_arr.size)

        c1_arr.zip(c2_arr) do |c1, c2| 
            assert_equal(c1.name, c2.name)
            assert_equal(c1.version, c2.version)
            assert_equal(c1.encoder, c2.encoder)
            assert_equal(c1.invalid_lines, c2.invalid_lines)
            assert_equal(c1.invalid_attributes, c2.invalid_attributes)

            atr = c1.attributes.map {|a| a.name} | c2.attributes.map {|a| a.name}
            atr.each do |a|
                a1 = c1.each(a).entries
                a2 = c2.each(a).entries

                if Component === a1.first
                    cmp_component_attributes(a1, a2)
                else
                    a1.zip(a2) {|x1, x2| assert_equal(x1, x2)}
                end
            end
        end
    end
end


EVENT_SONY_ERICSSON = VFormat['VCALENDAR', '1.0'].new do |c|
    c.VEVENT do |e|
        e.DTSTART  '20060706T120000Z'
        e.DTEND    [2006, 7, 6, 22, 0, 0, 'Z']
        e.SUMMARY  'Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m'
        e.LOCATION 'ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu'
        e.DALARM   '20060706T120000Z'
        e.AALARM   '20060706T120000Z'
        e.add 'LAST-MODIFIED', '20060705T160008Z'
        e.add 'X-IRMC-LUID',   '000000000017'
    end
end

EVENT_DATA_TIMEZONE1 = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTIMEZONE
TZID:ConvertedZone
BEGIN:DAYLIGHT
TZOFFSETFROM:-1000
TZOFFSETTO:-0900
TZNAME:PDT
DTSTART:19960407T115959
RRULE:FREQ=YEARLY
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:-0900
TZOFFSETTO:-1000
TZNAME:PST
DTSTART:19961027T100000
RRULE:FREQ=YEARLY
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTART;TZID=ConvertedZone:20060706T120000
END:VEVENT
END:VCALENDAR
EOT

EVENT_TIMEZONE1 = VFormat['VCALENDAR', '1.0'].new do |c|
    c.TZ '-10'
    c.DAYLIGHT ['TRUE', '-09:00', '19960407T115959', '19961027T100000', 'PST', 'PDT']
    c.VEVENT do |e|
        e.DTSTART  '20060706T120000'
    end
end

EVENT_DATA_TIMEZONE2 = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTIMEZONE
TZID:ConvertedZone
BEGIN:STANDARD
TZOFFSETFROM:+1000
TZOFFSETTO:+1000
DTSTART:19700101T000000
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTART;TZID=ConvertedZone:20060706T120000
END:VEVENT
END:VCALENDAR
EOT

EVENT_TIMEZONE2 = VFormat['VCALENDAR', '1.0'].new do |c|
    c.TZ '+10'
    c.VEVENT do |e|
        e.DTSTART  '20060706T120000'
    end
end

EVENT_DATA_EVOLUTION = <<EOT
BEGIN:VCALENDAR
PRODID:-//Ximian//NONSGML Evolution Calendar//EN
VERSION:2.0
METHOD:PUBLISH
BEGIN:VTIMEZONE
TZID:/softwarestudio.org/Olson_20011030_5/Europe/Prague
X-LIC-LOCATION:Europe/Prague
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=3
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=10
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
UID:20070509T090404Z-8063-10043-1-1@term12
DTSTAMP:20070509T090404Z
DTSTART;VALUE=DATE-TIME;
 TZID=/softwarestudio.org/Olson_20011030_5/Europe/Prague:20070509T090000
DTEND;VALUE=DATE-TIME;
 TZID=/softwarestudio.org/Olson_20011030_5/Europe/Prague:20070509T100000
TRANSP:OPAQUE
SEQUENCE:3
SUMMARY:test
CLASS:PUBLIC
CREATED:20070509T090409
LAST-MODIFIED:20070509T090409
END:VEVENT
END:VCALENDAR
EOT

 
RECUR_1 = [
    [
        "D2 #2",
        {
            :freq     => :daily,
            :count    => 2,
            :interval => 2,
        },
        {
            :freq     => :daily,
            :count    => 2,
            :interval => 2,
        },
    ],
    [
        "D1 #5 M10 #6",
        {
            :freq    => :daily,
            :count   => 5,
            :subrule => {:freq => :minutely, :count => 6, :interval => 10},
        },
        {
            :freq    => :daily,
            :count   => 5,
        },
    ],
    [
        "W1 TU 1200$ 1230 TH 1130 1200 #10",
        {
            :freq  => :weekly,
            :count => 10,
            :by    => ["TU", ["1200$", "1230"], "TH", ["1130", "1200"]],
        },
        {
            :freq      => :weekly,
            :count     => 80,
            :by_day    => [:tu, :th],
            :by_hour   => [12, 11],
            :by_minute => [0, 30],
        },
    ],
    [
        "W1 TU$ 1200 TH 1130 #10 M30",
        {
            :freq    => :weekly,
            :count   => 10,
            :by      => ["TU$", ["1200"], "TH", ["1130"]],
            :subrule => {:freq => :minutely, :interval => 30},
        },
        {
            :freq      => :weekly,
            :count     => 80,
            :by_day    => [:tu, :th],
            :by_hour   => [12, 11],
            :by_minute => [0, 30],
        },
    ],
    [
        "MP2 1+$ 1- FR #3",
        {
            :freq     => :monthlybypos,
            :interval => 2,
            :count    => 3,
            :by       => [["1+$", "1-"], ["FR"], []],
        },
        {
            :freq     => :monthly,
            :interval => 2,
            :count    => 6,
            :by_day   => [[1, :fr], [-1, :fr]],
        },
    ],
    [
        "MP6 1+ MO #5 D2 0600 1200 1500 #10 M5 #3",
        {
            :freq     => :monthlybypos,
            :interval => 6,
            :count    => 5,
            :by       => [["1+"], ["MO"], []],
            :subrule  => {
                :freq     => :daily,
                :interval => 2,
                :count    => 10,
                :by       => ["0600", "1200", "1500"],
                :subrule  => {
                    :freq     => :minutely,
                    :interval => 5,
                    :count    => 3,
                },
            },
        },
        {
            :freq     => :monthly,
            :interval => 6,
            :count    => 5,
            :by_day   => [[1, :mo]],
        },
    ],
    [
        "MD1 3- #0",
        {
            :freq  => :monthlybyday,
            :by    => ["3-"],
        },
        {
            :freq        => :monthly,
            :by_monthday => [-3],
        },
    ],
    [
        "YM1 1 3$ 8 #5 MD1 7 14$ 21 28",
        {
            :freq    => :yearlybymonth,
            :count   => 5,
            :by      => ["1", "3$", "8"],
            :subrule => {
                :freq  => :monthlybyday,
                :by    => ["7", "14$", "21", "28"],
            },
        },
        {
            :freq     => :yearly,
            :count    => 15,
            :by_month => [1, 3, 8],
        },
    ],
    [
        "YD1 1 100 D1 #5 19990102T000000Z",
        {
            :freq    => :yearlybyday,
            :until   => [1999, 1, 2, 0, 0, 0, "Z"],
            :by      => ["1", "100"],
            :subrule => {
                :freq  => :daily,
                :count => 5,
            },
        },
        {
            :freq        => :yearly,
            :until       => '19990102',
            :by_yearday  => [1, 100],
        },
    ],
]


RECUR_2 = [
    [
        "FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z",
        {
            :freq      => :hourly,
            :interval  => 3,
            :until     => '19970902T170000Z',
        },
        {
            :freq      => :daily,
            :interval  => 1,
            :by        => ["0000", "0300", "0600", "0900", "1200", "1500", "1800", "2100"],
            :until     => '19970902T170000Z',
        },
    ],
    [
        "FREQ=DAILY;INTERVAL=2;UNTIL=20071211",
        {
            :freq      => :daily,
            :interval  => 2,
            :until     => '20071211',
        },
        {
            :freq      => :daily,
            :interval  => 2,
            :until     => '20071211T000000',
        },
    ],
    [
        "FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH",
        {
            :freq      => :weekly,
            :count     => 10,
            :wkst      => :su,
            :by_day    => [:tu, :th],
        },
        {
            :freq      => :weekly,
            :count     => 5,
            :by        => ['TU', [], 'TH', []],
        },
    ],
    [
        "FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU",
        {
            :freq      => :monthly,
            :interval  => 2,
            :count     => 10,
            :by_day    => [[1, :su], [-1, :su]],
        },
        {
            :freq      => :monthlybypos,
            :interval  => 2,
            :count     => 5,
            :by        => [["1+"], ["SU"], [], ["1-"], ["SU"], []],
        },
    ],
    [
        "FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3",
        {
            :freq      => :monthly,
            :count     => 3,
            :by_day    => [:tu, :we, :th],
            :by_setpos => 3,
        },
        {
            :freq      => :monthlybypos,
            :count     => 1,
            :by        => [["3+"], ["TU"], [], ["3+"], ["WE"], [], ["3+"], ["TH"], []],
        },
    ],
    [
        "FREQ=MONTHLY;BYMONTHDAY=7,8,9,10,11,12,13",
        {
            :freq        => :monthly,
            :by_monthday => [7, 8, 9, 10, 11, 12, 13],
        },
        {
            :freq      => :monthlybyday,
            :by        => ['7', '8', '9', '10', '11', '12', '13'],
        },
    ],
    [
        "FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYMONTHDAY=2,3,4,5,6,7,8;BYDAY=TU",
        {
            :freq      => :yearly,
            :interval  => 4,
            :by_day    => :tu,
            :by_month  => 11,
            :by_monthday => [2, 3, 4, 5, 6, 7, 8],
        },
        {
            :freq      => :yearlybymonth,
            :interval  => 4,
            :by        => ['11'],
        },
    ],
    [
        "FREQ=YEARLY;BYMONTH=4;BYDAY=-1SU;BYHOUR=2;BYMINUTE=0",
        {
            :freq      => :yearly,
            :by_minute => 0,
            :by_hour   => [2],
            :by_month  => 4,
            :by_day    => [[-1, :su]],
        },
        {
            :freq    => :yearlybymonth,
            :by      => ["4"],
        },
    ],
    [
        "FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200",
        {
            :freq       => :yearly,
            :interval   => 3,
            :count      => 10,
            :by_yearday => [1, 100, 200],
        },
        {
            :freq     => :yearlybyday,
            :interval => 3,
            :count    => 4,
            :by       => ["1", "100", "200"],
        },
    ],
    
]

VCARD_DATA_RFC2425_EXAMPLE_2 = <<EOT
begin:VCARD
source:ldap://cn=bjorn%20Jensen, o=university%20of%20Michigan, c=US
name:Bjorn Jensen
fn:Bj=F8rn Jensen
n:Jensen;Bj=F8rn
email;type=internet:bjorn@umich.edu
tel;type=work,voice,msg:+1 313 747-4454
key;type=x509;encoding=B:dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK
end:VCARD
EOT

VCARD_DATA_RFC2425_EXAMPLE_3 = <<EOT
begin:vcard
source:ldap://cn=Meister%20Berger,o=Universitaet%20Goerlitz,c=DE
name:Meister Berger
fn:Meister Berger
n:Berger;Meister
bday;value=date:1963-09-21
org:Universit=E6t G=F6rlitz
title;language=de;value=text:Burgermeister
note:The Mayor of the great city of
  Goerlitz in the great country of Germany.
email;internet:mb@goerlitz.de
home.tel;type=fax,voice,msg:+49 3581 123456
home.label:Hufenshlagel 1234\\n
 02828 Goerlitz\\n
 Deutschland
key;type=X509;encoding=b:MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQ
 AwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bmljYXRpb25zI
 ENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0ZW1zMRwwGgYDVQQD
 ExNyb290Y2EubmV0c2NhcGUuY29tMB4XDTk3MDYwNjE5NDc1OVoXDTk3MTIwMzE5NDc
 1OVowgYkxCzAJBgNVBAYTAlVTMSYwJAYDVQQKEx1OZXRzY2FwZSBDb21tdW5pY2F0aW
 9ucyBDb3JwLjEYMBYGA1UEAxMPVGltb3RoeSBBIEhvd2VzMSEwHwYJKoZIhvcNAQkBF
 hJob3dlc0BuZXRzY2FwZS5jb20xFTATBgoJkiaJk/IsZAEBEwVob3dlczBcMA0GCSqG
 SIb3DQEBAQUAA0sAMEgCQQC0JZf6wkg8pLMXHHCUvMfL5H6zjSk4vTTXZpYyrdN2dXc
 oX49LKiOmgeJSzoiFKHtLOIboyludF90CgqcxtwKnAgMBAAGjNjA0MBEGCWCGSAGG+E
 IBAQQEAwIAoDAfBgNVHSMEGDAWgBT84FToB/GV3jr3mcau+hUMbsQukjANBgkqhkiG9
 w0BAQQFAAOBgQBexv7o7mi3PLXadkmNP9LcIPmx93HGp0Kgyx1jIVMyNgsemeAwBM+M
 SlhMfcpbTrONwNjZYW8vJDSoi//yrZlVt9bJbs7MNYZVsyF1unsqaln4/vy6Uawfg8V
 UMk1U7jt8LYpo4YULU7UZHPYVUaSgVttImOHZIKi4hlPXBOhcUQ==
end:vcard
EOT

VCARD_DATA_RFC2425_EXAMPLE_3_21 = <<EOT
BEGIN:VCARD
VERSION:2.1
SOURCE:ldap://cn=Meister%20Berger,o=Universitaet%20Goerlitz,c=DE
NAME:Meister Berger
FN:Meister Berger
N:Berger;Meister
BDAY:19630921
ORG:Universit=E6t G=F6rlitz
TITLE;LANGUAGE=de:Burgermeister
NOTE;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:The Mayor of the great city o=
f Goerlitz in the great country of Germany.
EMAIL;INTERNET:mb@goerlitz.de
HOME.TEL;FAX;VOICE;MSG:+49 3581 123456
HOME.LABEL;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:Hufenshlagel 1234=0A028=
28 Goerlitz=0ADeutschland
KEY;X509;ENCODING=BASE64:
 MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMC
 VVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bmljYXRpb25zIENvcnBvcmF0
 aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0ZW1zMRwwGgYDVQQDExNy
 b290Y2EubmV0c2NhcGUuY29tMB4XDTk3MDYwNjE5NDc1OVoXDTk3MTIwMzE5
 NDc1OVowgYkxCzAJBgNVBAYTAlVTMSYwJAYDVQQKEx1OZXRzY2FwZSBDb21t
 dW5pY2F0aW9ucyBDb3JwLjEYMBYGA1UEAxMPVGltb3RoeSBBIEhvd2VzMSEw
 HwYJKoZIhvcNAQkBFhJob3dlc0BuZXRzY2FwZS5jb20xFTATBgoJkiaJk/Is
 ZAEBEwVob3dlczBcMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQC0JZf6wkg8pLMX
 HHCUvMfL5H6zjSk4vTTXZpYyrdN2dXcoX49LKiOmgeJSzoiFKHtLOIboylud
 F90CgqcxtwKnAgMBAAGjNjA0MBEGCWCGSAGG+EIBAQQEAwIAoDAfBgNVHSME
 GDAWgBT84FToB/GV3jr3mcau+hUMbsQukjANBgkqhkiG9w0BAQQFAAOBgQBe
 xv7o7mi3PLXadkmNP9LcIPmx93HGp0Kgyx1jIVMyNgsemeAwBM+MSlhMfcpb
 TrONwNjZYW8vJDSoi//yrZlVt9bJbs7MNYZVsyF1unsqaln4/vy6Uawfg8VU
 Mk1U7jt8LYpo4YULU7UZHPYVUaSgVttImOHZIKi4hlPXBOhcUQ==

END:VCARD
EOT

VCARD_DATA_STRUCTURED_1_30 = <<EOT
BEGIN:VCARD
VERSION:3.0
ADR:a;\\,b\\,c;d\\,e;;
END:VCARD
EOT

VCARD_DATA_STRUCTURED_1_21 = <<EOT
BEGIN:VCARD
VERSION:2.1
ADR:a;,b,c;d,e;;
END:VCARD
EOT

VCARD_DATA_STRUCTURED_2_30 = <<EOT
BEGIN:VCARD
VERSION:3.0
ADR:a;,b\\,c;d,e;;
END:VCARD
EOT

VCARD_DATA_STRUCTURED_2_21 = <<EOT
BEGIN:VCARD
VERSION:2.1
ADR:a;;d;;
END:VCARD
EOT

