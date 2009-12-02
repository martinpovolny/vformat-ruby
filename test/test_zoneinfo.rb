#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
#  License: GPL
#

require(File.join(File.dirname(__FILE__), "common"))

class TestZoneInfo < Test::Unit::TestCase
    def setup
        @test_zones = ZoneInfo::LOCATION_TO_STRUCT.map do |location, s|
            tz = VFormat.decode(File.read(File.join(File.dirname(__FILE__), "zoneinfo", location + '.ics'))).first
            tz = tz['VTIMEZONE']

            tz['TZID'] = tz['X-LIC-LOCATION']

            # opravime poradi komponent
            #
            st = tz.delete('STANDARD').first
            dl = tz.delete('DAYLIGHT').first
            tz.attributes << dl if dl
            tz.attributes << st
            
            # opravy bugu v TZFROM v puvodnich ics
            #
            if dl
                st['TZOFFSETFROM'] = dl['TZOFFSETTO']
                dl['TZOFFSETFROM'] = st['TZOFFSETTO']
            end

            tz
        end
    end

    def test_new_for_location
        @test_zones.each do |tz|
            our = VFormat['VTIMEZONE'].new_for_location(tz['X-LIC-LOCATION'].value)
            cmp_component_attributes([tz], [our])
            assert_equal_encoded(tz.encode, our.encode)
        end
    end

    def test_locations
        require 'vformat/zoneinfo'

        @test_zones.each do |tz|
            struct = tz.to_zoneinfo_struct

            assert_equal(
                ZoneInfo::STRUCT_TO_LOCATION[ZoneInfo::STRUCTS.index(struct)],
                ZoneInfo.locations(struct)
            )
        end
    end
end


