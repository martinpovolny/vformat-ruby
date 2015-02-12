# encoding: UTF-8
#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

require(File.join(File.dirname(__FILE__), "common"))

class TestEncode < Test::Unit::TestCase

    def test_attribute

        assert_equal(
            "TEST;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:long =0A line long =0A line l=\r\nong =0A line long =0A line long =0A line long =0A line long =0A line long =\r\n=0A line \r\n",
            Attribute.new('TEST', "long \n line " * 8, :encoder => Encoder::VCARD21).encode
        )
        assert_equal(
            "TEST:long \\n line long \\n line long \\n line long \\n line long \\n line long \r\n \\n line long \\n line long \\n line \r\n",
            Attribute.new('TEST', "long \n line " * 8).encode
        )
        assert_equal(
            "TEST;A=a,b,c;B=\"a;b\",\"c,d\":test\r\n",
            Attribute.new('TEST', 'test', 'A' => %w{a b c}, 'B' => %w{a;b c,d}).encode
        )

        a = Attribute.new('TEST', [%w(a b c), %w(d e), ['']], :default_value_type => :structured)
        assert_equal("TEST:a,b,c;d,e;\r\n", a.encode)

        a = Attribute.new('TEST', [%w(a,b,c), %w(d,e), ['']], :default_value_type => :structured)
        assert_equal("TEST:a\\,b\\,c;d\\,e;\r\n", a.encode)

        a = Attribute.new('TEST', ['a,b,c', 'd,e', ''], :default_value_type => :text_list, :encoder => Encoder::VCARD21)
        assert_equal("TEST:a,b,c;d,e;\r\n", a.encode)
    end

    def test_event
        c = VFormat['VCALENDAR'].new do |c|
            c.VEVENT do |e|
                e.SUMMARY 'test'
            end
        end

        assert_equal_encoded(
            "BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:test\nEND:VEVENT\nEND:VCALENDAR\n",
            c.encode
        )

        c = VFormat['VCALENDAR'].new do |c|
            c.add_timezone('Europe/Prague')

            c.VEVENT do |e|
                e.DTSTART  '20060706T120000Z'
                e.DTEND    [2006, 7, 6, 22, 0, 0, 'Z']
                e.SUMMARY  'Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m'
                e.LOCATION 'ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu'
                e.add 'LAST-MODIFIED', '20060705T160008Z'
                e.add 'X-IRMC-LUID',   '000000000017'
            end
        end

        assert_equal_encoded(<<EOT, c.encode)
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Prague
X-LIC-LOCATION:Europe/Prague
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
DTSTART:20060706T120000Z
DTEND:20060706T220000Z
SUMMARY:Meeting+èΔΦüΔèåäæàÇΓñööøòßΠΠΣvzå@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m
LOCATION:ΔéèΔΦèéèΔåäΓ22gjptjgtjbjat+vj0tmj+t+tΘp0twuptxt+gu
LAST-MODIFIED:20060705T160008Z
X-IRMC-LUID:000000000017
END:VEVENT
END:VCALENDAR
EOT

        assert_equal_encoded(<<EOT, EVENT_SONY_ERICSSON.encode)
BEGIN:VCALENDAR
VERSION:1.0
BEGIN:VEVENT
DTSTART:20060706T120000Z
DTEND:20060706T220000Z
SUMMARY;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:Meeting+=C3=A8=CE=94=CE=A6=
=C3=BC=CE=94=C3=A8=C3=A5=C3=A4=C3=A6=C3=A0=C3=87=CE=93=C3=B1=C3=B6=C3=B6=
=C3=B8=C3=B2=C3=9F=CE=A0=CE=A0=CE=A3vz=C3=A5@mjogmdwgmtjdmgdnemjPDpmpmtdpw=
mgN.m
LOCATION;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=CE=94=C3=A9=C3=A8=CE=94=
=CE=A6=C3=A8=C3=A9=C3=A8=CE=94=C3=A5=C3=A4=CE=9322gjptjgtjbjat+vj0tmj+t+t=
=CE=98p0twuptxt+gu
DALARM:20060706T120000Z
AALARM;ENCODING=BASE64:
 MjAwNjA3MDZUMTIwMDAwWg==

LAST-MODIFIED:20060705T160008Z
X-IRMC-LUID:000000000017
END:VEVENT
END:VCALENDAR
EOT
    end

    def test_card
        # RFC2425 - 8.2. Example 2 and Example 3
        #
        c = VFormat['VCARD'].new do |c|
            c.SOURCE 'ldap://cn=bjorn%20Jensen, o=university%20of%20Michigan, c=US'
            c.NAME   'Bjorn Jensen'
            c.FN     'Bj=F8rn Jensen'
            c.N      %w(Jensen Bj=F8rn)
            c.EMAIL  'bjorn@umich.edu', 'TYPE' => 'INTERNET'
            c.TEL    '+1 313 747-4454', 'TYPE' => %w(WORK VOICE MSG)
            c.KEY    "this could be \nmy certificate\n", 'TYPE' => 'X509'
        end

        assert_equal_encoded(<<EOT, c.encode)
BEGIN:VCARD
VERSION:3.0
SOURCE:ldap://cn=bjorn%20Jensen, o=university%20of%20Michigan, c=US
NAME:Bjorn Jensen
FN:Bj=F8rn Jensen
N:Jensen;Bj=F8rn
EMAIL;TYPE=INTERNET:bjorn@umich.edu
TEL;TYPE=WORK,VOICE,MSG:+1 313 747-4454
KEY;ENCODING=b;TYPE=X509:
 dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK
END:VCARD
EOT

        # RFC2425 - 8.2. Example 3
        #
        c = VFormat['VCARD'].new do |c|
            c.SOURCE 'ldap://cn=Meister%20Berger,o=Universitaet%20Goerlitz,c=DE'
            c.NAME   'Meister Berger'
            c.FN     'Meister Berger'
            c.N      %w(Berger Meister)
            c.BDAY   [1963, 9, 21], :value_type => :date
            c.ORG    'Universit=E6t G=F6rlitz'
            c.TITLE  'Mayor'
            c.TITLE  'Burgermeister', 'LANGUAGE' => 'de'
            c.NOTE   'The Mayor of the great city of Goerlitz in the great country of Germany.'
            c.EMAIL  'mb@goerlitz.de', 'TYPE' => 'INTERNET'
            c.TEL    '+49 3581 123456', :group => 'HOME', 'TYPE' => %w(FAX VOICE MSG)
            c.LABEL  "Hufenshlagel 1234\n02828 Goerlitz\nDeutschland", :group => 'HOME'
            c.KEY    "0\202\002j0\202\001\323\240\003\002\001\002\002\002\004E0\r\006\t*\206H\206\367\r\001\001\004\005\0000w1\v0\t\006\003U\004\006\023\002US1,0*\006\003U\004\n\023#Netscape Communications Corporation1\0340\032\006\003U\004\v\023\023Information Systems1\0340\032\006\003U\004\003\023\023rootca.netscape.com0\036\027\r970606194759Z\027\r971203194759Z0\201\2111\v0\t\006\003U\004\006\023\002US1&0$\006\003U\004\n\023\035Netscape Communications Corp.1\0300\026\006\003U\004\003\023\017Timothy A Howes1!0\037\006\t*\206H\206\367\r\001\t\001\026\022howes@netscape.com1\0250\023\006\n\t\222&\211\223\362,d\001\001\023\005howes0\\0\r\006\t*\206H\206\367\r\001\001\001\005\000\003K\0000H\002A\000\264%\227\372\302H<\244\263\027\034p\224\274\307\313\344~\263\215)8\2754\327f\2262\255\323vuw(_\217K*#\246\201\342R\316\210\205({K8\206\350\312[\235\027\335\002\202\2471\267\002\247\002\003\001\000\001\2436040\021\006\t`\206H\001\206\370B\001\001\004\004\003\002\000\2400\037\006\003U\035#\004\0300\026\200\024\374\340T\350\a\361\225\336:\367\231\306\256\372\025\fn\304.\2220\r\006\t*\206H\206\367\r\001\001\004\005\000\003\201\201\000^\306\376\350\356h\267<\265\332vI\215?\322\334 \371\261\367q\306\247B\240\313\035c!S26\v\036\231\3400\004\317\214JXL}\312[N\263\215\300\330\331ao/$4\250\213\377\362\255\231U\267\326\311n\316\3145\206U\263!u\272{*jY\370\376\374\272Q\254\037\203\305T2MT\356;|-\212h\341\205\vS\265\031\034\366\025Q\244\240V\333H\230\341\331 \250\270\206S\327\004\350\\Q",
                     'TYPE' => 'X509'
        end

        assert_equal_encoded(<<EOT, c.encode)
BEGIN:VCARD
VERSION:3.0
SOURCE:ldap://cn=Meister%20Berger,o=Universitaet%20Goerlitz,c=DE
NAME:Meister Berger
FN:Meister Berger
N:Berger;Meister
BDAY:19630921
ORG:Universit=E6t G=F6rlitz
TITLE:Mayor
TITLE;LANGUAGE=de:Burgermeister
NOTE:The Mayor of the great city of Goerlitz in the great country of German
 y.
EMAIL;TYPE=INTERNET:mb@goerlitz.de
HOME.TEL;TYPE=FAX,VOICE,MSG:+49 3581 123456
HOME.LABEL:Hufenshlagel 1234\\n02828 Goerlitz\\nDeutschland
KEY;ENCODING=b;TYPE=X509:
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
    end

    def test_recur
        # vCalendar 2.0
        #
        RECUR_2.each do |str, rule|
            assert_equal_encoded(
                <<"EOT",
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
RRULE:#{str}
END:VEVENT
END:VCALENDAR
EOT
                VFormat['VCALENDAR', '2.0'].new {|c| c.VEVENT {|e| e.RRULE rule }}.encode
            )
        end


        # vCalendar 1.0
        #
        RECUR_1.each do |str, rule|
            assert_equal_encoded(
                <<"EOT",
BEGIN:VCALENDAR
VERSION:1.0
BEGIN:VEVENT
RRULE:#{str}
END:VEVENT
END:VCALENDAR
EOT
                VFormat['VCALENDAR', '1.0'].new {|c| c.VEVENT {|e| e.RRULE rule }}.encode
            )
        end
    end
end

