#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

require(File.join(File.dirname(__FILE__), "common"))

class TestConvert < Test::Unit::TestCase
    def test_recur
        RECUR_1.each do |str, rule, rule2|
            next unless rule2
            cmp_component_attributes(
                [VFormat['VCALENDAR', '2.0'].new {|c| c.VEVENT {|e| e.RRULE rule2 }}],
                [VFormat['VCALENDAR', '1.0'].new {|c| c.VEVENT {|e| e.RRULE rule }}.to_version('2.0')]
            )
        end

        RECUR_2.each do |str, rule, rule2|
            next unless rule2
            cmp_component_attributes(
                [VFormat['VCALENDAR', '1.0'].new {|c| c.VEVENT {|e| e.RRULE rule2 }}],
                [VFormat['VCALENDAR', '2.0'].new {|c| c.VEVENT {|e| e.RRULE rule }}.to_version('1.0')]
            )
        end
    end

    def test_timezone
        assert_equal_encoded(
            EVENT_DATA_TIMEZONE1, 
            EVENT_TIMEZONE1.to_version('2.0').encode
        )
        assert_equal_encoded(
            EVENT_DATA_TIMEZONE2, 
            EVENT_TIMEZONE2.to_version('2.0').encode
        )

        cmp_component_attributes(
            [EVENT_TIMEZONE1],
            [VFormat.decode(EVENT_DATA_TIMEZONE1).first.to_version('1.0')]
        )
        cmp_component_attributes(
            [EVENT_TIMEZONE2],
            [VFormat.decode(EVENT_DATA_TIMEZONE2).first.to_version('1.0')]
        )

        assert_equal_encoded(
            <<EOT,
BEGIN:VCALENDAR
VERSION:1.0
TZ:+01:00
DAYLIGHT:TRUE;+02:00;19700329T020000;19701025T030000;CET;CEST
PRODID:-//Ximian//NONSGML Evolution Calendar//EN
BEGIN:VEVENT
UID:20070509T090404Z-8063-10043-1-1@term12
DTSTART:20070509T090000
DTEND:20070509T100000
SEQUENCE:3
SUMMARY:test
CLASS:PUBLIC
LAST-MODIFIED:20070509T090409
END:VEVENT
END:VCALENDAR
EOT
            VFormat.decode(EVENT_DATA_EVOLUTION).first.to_version('1.0').encode
        )
    end

    def test_structured
        cmp_component_attributes(
            VFormat.decode(VCARD_DATA_STRUCTURED_1_21),
            [VFormat.decode(VCARD_DATA_STRUCTURED_1_30).first.to_version('2.1')]
        )

        cmp_component_attributes(
            VFormat.decode(VCARD_DATA_STRUCTURED_1_30),
            [VFormat.decode(VCARD_DATA_STRUCTURED_1_21).first.to_version('3.0')]
        )

        cmp_component_attributes(
            VFormat.decode(VCARD_DATA_STRUCTURED_2_21),
            [VFormat.decode(VCARD_DATA_STRUCTURED_2_30).first.to_version('2.1')]
        )
    end

    def test_card
        cmp_component_attributes(
            VFormat.decode(VCARD_DATA_RFC2425_EXAMPLE_3_21),
            [VFormat.decode(VCARD_DATA_RFC2425_EXAMPLE_3).first.to_version('2.1')]
        )

        cmp_component_attributes(
            VFormat.decode(VCARD_DATA_RFC2425_EXAMPLE_3),
            [VFormat.decode(VCARD_DATA_RFC2425_EXAMPLE_3_21).first.to_version('3.0')]
        )
    end
end


