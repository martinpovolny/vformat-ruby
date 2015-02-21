#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

require(File.join(File.dirname(__FILE__), "common"))
#             p VFormat.decode(<<EOT).first.VEVENT.SUMMARY.value.encoding
# BEGIN:VCALENDAR
# VERSION:1.0
# BEGIN:VEVENT
# DTSTART:20060706T120000Z
# DTEND:20060706T220000Z
# SUMMARY;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:Meeting+=C3=A8=CE=94=CE=A6==
# C3=BC=CE=94=C3=A8=C3=A5=C3=A4=C3=A6=C3=A0=C3=87=CE=93=C3=B1=C3=B6=C3=B6=C3==
# B8=C3=B2=C3=9F=CE=A0=CE=A0=CE=A3vz=C3=A5@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m=
# 
# LOCATION;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=CE=94=C3=A9=C3=A8=CE=94=C=
# E=A6=C3=A8=C3=A9=C3=A8=CE=94=C3=A5=C3=A4=CE=9322gjptjgtjbjat+vj0tmj+t+t=CE==
# 98p0twuptxt+gu
# DALARM:20060706T120000Z
# AALARM:20060706T120000Z
# LAST-MODIFIED:20060705T160008Z
# X-IRMC-LUID:000000000017
# END:VEVENT
# END:VCALENDAR
# EOT
# exit 0

class TestDecode < Test::Unit::TestCase
    def test_attribute
        assert_equal(
            Attribute.new('TEST', "long \n line " * 6),
            Attribute.decode(
                "test;quoted-printable;charset=utf-8:long =0A line long =0A line long =0A line long =0A line long =0A line long =0A line "
            ).decode_raw_value(:text)
        )
        assert_equal(
            Attribute.new('TEST', "long \n line " * 6),
            Attribute.decode(
                "test:long \\n line long \\n line long \\n line long \\n line long \\n line long \\n line "
            ).decode_raw_value(:text)
        )

        assert_equal(
            Attribute.new('TEST', [%w(a b c), %w(d e), ['']], :value_type => :structured),
            Attribute.decode("test:a,b,c;d,e;").decode_raw_value(:structured)
        )

        assert_equal(
            Attribute.new('TEST', ['a,b,c', 'd,e', ''], :value_type => :structured, :encoder => Encoder::VCARD21),
            Attribute.decode("test:a,b,c;d,e;", Encoder::VCARD21).decode_raw_value(:structured)
        )

        assert_equal(
            Attribute.new('TEST', [%w(a; b\\,c), %w(d e), [''], %w(\\)], :value_type => :structured),
            Attribute.decode("test:a\\;,b\\\\\\,c;d,e;;\\").decode_raw_value(:structured)
        )

        assert_equal(
            Attribute.new('TEST', ['a;,b\\\\,c', 'd,e', '', '\\'], :value_type => :structured, :encoder => Encoder::VCARD21),
            Attribute.decode("test:a\\;,b\\\\\\,c;d,e;;\\", Encoder::VCARD21).decode_raw_value(:structured)
        )

        cal = VFormat['VEVENT'].new do |e|
            e.SUMMARY 'test'
            e.DTSTART [2007, 12, 10, 1, 1, 1]
        end

        assert_equal(cal.SUMMARY.value.type, :text)
        assert_equal(cal.DTSTART.value.type, :date_time)
    end

    def test_event
        cmp_component_attributes(
            [VFormat['VEVENT'].new do |e|
                e.SUMMARY 'test'
            end
            ],

            VFormat.decode(
                "BEGIN:VEVENT\r\nSUMMARY:test\r\nEND:VEVENT\r\n"
            )
        )

        cmp_component_attributes(
            [VFormat['VCALENDAR'].new do |c|
                c.VEVENT do |e|
                    e.SUMMARY 'test'
                end
            end],

            VFormat.decode(
                "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\nSUMMARY:test\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"
            )
        )

        # event from Sony Ericsson k750
        #
        cmp_component_attributes(
            [EVENT_SONY_ERICSSON],

            VFormat.decode(<<EOT)
BEGIN:VCALENDAR
VERSION:1.0
BEGIN:VEVENT
DTSTART:20060706T120000Z
DTEND:20060706T220000Z
SUMMARY;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:Meeting+=C3=A8=CE=94=CE=A6==
C3=BC=CE=94=C3=A8=C3=A5=C3=A4=C3=A6=C3=A0=C3=87=CE=93=C3=B1=C3=B6=C3=B6=C3==
B8=C3=B2=C3=9F=CE=A0=CE=A0=CE=A3vz=C3=A5@mjogmdwgmtjdmgdnemjPDpmpmtdpwmgN.m=

LOCATION;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=CE=94=C3=A9=C3=A8=CE=94=C=
E=A6=C3=A8=C3=A9=C3=A8=CE=94=C3=A5=C3=A4=CE=9322gjptjgtjbjat+vj0tmj+t+t=CE==
98p0twuptxt+gu
DALARM:20060706T120000Z
AALARM:20060706T120000Z
LAST-MODIFIED:20060705T160008Z
X-IRMC-LUID:000000000017
END:VEVENT
END:VCALENDAR
EOT
        )


        # from Vpim
        #
        ical = <<EOT
BEGIN:VCALENDAR
VERSION:2.0
METHOD:REQUEST
PRODID:-//Lotus Development Corporation//NONSGML Notes 6.0//EN
X-LOTUS-CHARSET:UTF-8
BEGIN:VTIMEZONE
TZID:Pacific
BEGIN:STANDARD
DTSTART:19501029T020000
TZOFFSETFROM:-0700
TZOFFSETTO:-0800
RRULE:FREQ=YEARLY;BYMINUTE=0;BYHOUR=2;BYDAY=-1SU;BYMONTH=10
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:19500402T020000
TZOFFSETFROM:-0800
TZOFFSETTO:-0700
RRULE:FREQ=YEARLY;BYMINUTE=0;BYHOUR=2;BYDAY=1SU;BYMONTH=4
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
ATTENDEE;CN=Gary Pope/Certicom;PARTSTAT=ACCEPTED;ROLE=CHAIR;RSVP=FALSE:mail
 to:gpope@certicom.com
ATTENDEE;CN=Mike Harvey/Certicom;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT
 ;RSVP=TRUE:mailto:MHarvey@certicom.com
ATTENDEE;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT;RSVP=TRUE:mailto:rgalla
 nt@emilpost.certicom.com
ATTENDEE;CN=Sam Roberts/Certicom;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPANT
 ;RSVP=TRUE:mailto:SRoberts@certicom.com
ATTENDEE;CN=Tony Walters/Certicom;PARTSTAT=NEEDS-ACTION;ROLE=REQ-PARTICIPAN
 T;RSVP=TRUE:mailto:TWalters@certicom.com
CLASS:PUBLIC
DTEND;TZID=Pacific:20040415T130000
DTSTAMP:20040319T205045Z
DTSTART;TZID=Pacific:20040415T120000
ORGANIZER;CN=Gary Pope/Certicom:mailto:gpope@certicom.com
SEQUENCE:0
SUMMARY:hjold intyel
TRANSP:OPAQUE
UID:3E19204063C93D2388256E5C006BF8D9-Lotus_Notes_Generated
X-LOTUS-BROADCAST:FALSE
X-LOTUS-CHILD_UID:3E19204063C93D2388256E5C006BF8D9
X-LOTUS-NOTESVERSION:2
X-LOTUS-NOTICETYPE:I
X-LOTUS-UPDATE-SEQ:1
X-LOTUS-UPDATE-WISL:$S:1;$L:1;$B:1;$R:1;$E:1
END:VEVENT
END:VCALENDAR
EOT
        cmp_component_attributes(
            VFormat.decode(ical),
            VFormat.decode(VFormat.decode(ical).first.encode)
        )
    end

    def test_card
        # RFC2425 - 8.2. Example 2 and Example 3
        # z druheho vCardu byl smazan "title:Mayor"
        #
        cmp_component_attributes(
            [VFormat['VCARD'].new do |c|
                c.SOURCE 'ldap://cn=bjorn%20Jensen, o=university%20of%20Michigan, c=US'
                c.NAME   'Bjorn Jensen'
                c.FN     'Bj=F8rn Jensen'
                c.N      %w(Jensen Bj=F8rn)
                c.EMAIL  'bjorn@umich.edu', 'TYPE' => 'INTERNET'
                c.TEL    '+1 313 747-4454', 'TYPE' => %w(WORK VOICE MSG)
                c.KEY    "this could be \nmy certificate\n", 'TYPE' => 'X509'
            end,

            VFormat['VCARD'].new do |c|
                c.SOURCE 'ldap://cn=Meister%20Berger,o=Universitaet%20Goerlitz,c=DE'
                c.NAME   'Meister Berger'
                c.FN     'Meister Berger'
                c.N      %w(Berger Meister)
                c.BDAY   [1963, 9, 21], :value_type => :date
                c.ORG    'Universit=E6t G=F6rlitz'
                c.TITLE  'Burgermeister', 'LANGUAGE' => 'de'
                c.NOTE   'The Mayor of the great city of Goerlitz in the great country of Germany.'
                c.EMAIL  'mb@goerlitz.de', 'TYPE' => 'INTERNET'
                c.TEL    '+49 3581 123456', :group => 'HOME', 'TYPE' => %w(FAX VOICE MSG)
                c.LABEL  "Hufenshlagel 1234\n02828 Goerlitz\nDeutschland", :group => 'HOME'
                c.KEY    "0\202\002j0\202\001\323\240\003\002\001\002\002\002\004E0\r\006\t*\206H\206\367\r\001\001\004\005\0000w1\v0\t\006\003U\004\006\023\002US1,0*\006\003U\004\n\023#Netscape Communications Corporation1\0340\032\006\003U\004\v\023\023Information Systems1\0340\032\006\003U\004\003\023\023rootca.netscape.com0\036\027\r970606194759Z\027\r971203194759Z0\201\2111\v0\t\006\003U\004\006\023\002US1&0$\006\003U\004\n\023\035Netscape Communications Corp.1\0300\026\006\003U\004\003\023\017Timothy A Howes1!0\037\006\t*\206H\206\367\r\001\t\001\026\022howes@netscape.com1\0250\023\006\n\t\222&\211\223\362,d\001\001\023\005howes0\\0\r\006\t*\206H\206\367\r\001\001\001\005\000\003K\0000H\002A\000\264%\227\372\302H<\244\263\027\034p\224\274\307\313\344~\263\215)8\2754\327f\2262\255\323vuw(_\217K*#\246\201\342R\316\210\205({K8\206\350\312[\235\027\335\002\202\2471\267\002\247\002\003\001\000\001\2436040\021\006\t`\206H\001\206\370B\001\001\004\004\003\002\000\2400\037\006\003U\035#\004\0300\026\200\024\374\340T\350\a\361\225\336:\367\231\306\256\372\025\fn\304.\2220\r\006\t*\206H\206\367\r\001\001\004\005\000\003\201\201\000^\306\376\350\356h\267<\265\332vI\215?\322\334 \371\261\367q\306\247B\240\313\035c!S26\v\036\231\3400\004\317\214JXL}\312[N\263\215\300\330\331ao/$4\250\213\377\362\255\231U\267\326\311n\316\3145\206U\263!u\272{*jY\370\376\374\272Q\254\037\203\305T2MT\356;|-\212h\341\205\vS\265\031\034\366\025Q\244\240V\333H\230\341\331 \250\270\206S\327\004\350\\Q".force_encoding_vformat("ASCII-8BIT"),
                         'TYPE' => 'X509'
            end],
            VFormat.decode(VCARD_DATA_RFC2425_EXAMPLE_2 + "\n" + VCARD_DATA_RFC2425_EXAMPLE_3)
        )
    end

    def test_recur
        # vCalendar 2.0
        #
        RECUR_2.each do |str, rule|
            cmp_component_attributes(
                [VFormat['VCALENDAR', '2.0'].new {|c| c.VEVENT {|e| e.RRULE rule }}],
                VFormat.decode(<<"EOT"))
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
RRULE:#{str}
END:VEVENT
END:VCALENDAR
EOT
       end

        # vCalendar 1.0
        #
        (RECUR_1 + [[
            "D2",
            {
                :freq     => :daily,
                :count    => 2,
                :interval => 2,
            },
        ]]).each do |str, rule|
            cmp_component_attributes(
                [VFormat['VCALENDAR', '1.0'].new {|c| c.VEVENT {|e| e.RRULE rule }}],
                VFormat.decode(<<"EOT"))
BEGIN:VCALENDAR
VERSION:1.0
BEGIN:VEVENT
RRULE:#{str}
END:VEVENT
END:VCALENDAR
EOT
       end
    end
end

