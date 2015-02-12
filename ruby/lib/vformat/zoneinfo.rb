#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#

module VFormat
    # Prevod nazvu Olson timezon do VTIMEZONE a zpet.
    #
    module ZoneInfo
        # data pro vytvoreni VTIMEZONE (:st_* data pro STANDARD, :dl_* data pro DAYLIGHT)
        #
        class StStruct < Struct.new(nil, :st_offset, :st_name)
            def has_dl?
                false
            end
        end

        class StDlStruct < Struct.new(
            nil, 
            :st_offset, 
            :dl_offset,
            :st_name,     # muze byt nil
            :dl_name,     # muze byt nil
            :st_wday,     # muze byt nil
            :dl_wday,     # muze byt nil
            :st_wday_pos, # muze byt nil
            :dl_wday_pos, # muze byt nil
            :st_year,     # muze byt nil
            :st_month,
            :st_day,
            :st_hour,
            :st_min,
            :st_sec,
            :dl_year,     # muze byt nil
            :dl_month,
            :dl_day,
            :dl_hour,
            :dl_min,
            :dl_sec
        )
            def has_dl?
                true
            end

            def set_st_from_date_time(time)
                self.st_year  = time.year
                self.st_month = time.month
                self.st_day   = time.day
                self.st_hour  = time.hour
                self.st_min   = time.min
                self.st_sec   = time.sec.to_i
            end

            def st_date_time_a
                [st_year || 1970, st_month, st_day, st_hour, st_min, st_sec]
            end

            def set_dl_from_date_time(time)
                self.dl_year  = time.year
                self.dl_month = time.month
                self.dl_day   = time.day
                self.dl_hour  = time.hour
                self.dl_min   = time.min
                self.dl_sec   = time.sec.to_i
            end

            def dl_date_time_a
                [dl_year || 1970, dl_month, dl_day, dl_hour, dl_min, dl_sec]
            end

        end

        # Pokusi se zjistit nazvy Olson timezon (napr. ['Europe/Prague',
        # 'Europe/Paris', ...]), ktere matchuji timezonu zadanou pomoci
        # +VFormat::ZoneInfo::StStruct+ nebo +VFormat::ZoneInfo::StDlStruct+.
        #
        # Muze vratit [].
        #
        def self.locations(struct)
            result = []

            if struct.has_dl?
                return result unless structs = OFFSET_TO_STRUCT[
                    [
                        struct.st_offset,
                        struct.dl_offset,
                        struct.st_month,
                        struct.st_hour,
                        struct.st_min,
                        struct.st_sec,
                        struct.dl_month,
                        struct.dl_hour,
                        struct.dl_min,
                        struct.dl_sec,
                    ].join(" ")
                ]
                structs = structs.to_a

                # vyfiltrujeme shodne Structs
                # 
                structs = structs.delete_if do |model| 
                    model = STRUCTS[model]

                    not (
                      (struct.st_wday.nil? or struct.st_wday == model.st_wday) and
                      (struct.dl_wday.nil? or struct.dl_wday == model.dl_wday) and
                      (struct.st_wday_pos.nil? or struct.st_wday_pos == model.st_wday_pos) and
                      (struct.dl_wday_pos.nil? or struct.dl_wday_pos == model.dl_wday_pos)
                    )
                end
            else
                return result unless structs = OFFSET_TO_STRUCT[struct.st_offset.to_s]
                structs = structs.to_a
            end

            if structs.size > 1 and struct.st_name
                # zkusime, zda lze vyfiltrovat Structs se shodnymi nazvy 
                # 
                new_structs = structs.reject do |model|
                    model = STRUCTS[model]

                    struct.st_name != model.st_name or (
                        struct.has_dl? and struct.dl_name and struct.dl_name != model.dl_name
                    )
                end
                structs = new_structs unless new_structs.empty?
            end

            structs.each {|model| result.concat(STRUCT_TO_LOCATION[model]) }
            result
        end


        ## GENERATED-BEGIN ##
        s = StStruct
        d = StDlStruct

        STRUCTS = [
            s.new(-39600, "NUT"), # 0
            s.new(-39600, "WST"), # 1
            s.new(-39600, "SST"), # 2
            s.new(-36000, "TKT"), # 3
            s.new(-36000, "CKT"), # 4
            s.new(-36000, "HST"), # 5
            s.new(-36000, "TAHT"), # 6
            d.new(-36000, -32400, "HAST", "HADT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 7
            s.new(-34200, "MART"), # 8
            s.new(-32400, "GAMT"), # 9
            d.new(-32400, -28800, "AKST", "AKDT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 10
            s.new(-28800, "PST"), # 11
            d.new(-28800, -25200, "PST", "PDT", :su, :su, -1, 1, 1970, 10, 25, 2, 0, 0, 1970, 4, 5, 2, 0, 0), # 12
            d.new(-28800, -25200, "PST", "PDT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 13
            s.new(-25200, "MST"), # 14
            d.new(-25200, -21600, "MST", "MDT", :su, :su, -1, 1, 1970, 10, 25, 2, 0, 0, 1970, 4, 5, 2, 0, 0), # 15
            d.new(-25200, -21600, "MST", "MDT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 16
            s.new(-21600, "CST"), # 17
            s.new(-21600, "GALT"), # 18
            d.new(-21600, -18000, "EAST", "EASST", :sa, :sa, 2, 2, 1970, 3, 14, 22, 0, 0, 1970, 10, 10, 22, 0, 0), # 19
            d.new(-21600, -18000, "CST", "CDT", :su, :su, -1, 1, 1970, 10, 25, 2, 0, 0, 1970, 4, 5, 2, 0, 0), # 20
            d.new(-21600, -18000, "CST", "CDT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 21
            s.new(-18000, "EST"), # 22
            s.new(-18000, "PET"), # 23
            s.new(-18000, "ECT"), # 24
            s.new(-18000, "ACT"), # 25
            s.new(-18000, "COT"), # 26
            d.new(-18000, -14400, "CST", "CDT", :su, :su, 1, 2, 1970, 11, 1, 1, 0, 0, 1970, 3, 8, 0, 0, 0), # 27
            d.new(-18000, -14400, "EST", "EDT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 28
            s.new(-14400, "GYT"), # 29
            s.new(-14400, "AMT"), # 30
            s.new(-14400, "BOT"), # 31
            s.new(-14400, "AST"), # 32
            s.new(-14400, "VET"), # 33
            d.new(-14400, -10800, "AMT", "AMST", :su, :su, -1, 1, 1970, 2, 22, 0, 0, 0, 1970, 11, 1, 0, 0, 0), # 34
            d.new(-14400, -10800, "CLT", "CLST", :su, :su, 2, 2, 1970, 3, 15, 0, 0, 0, 1970, 10, 11, 0, 0, 0), # 35
            d.new(-14400, -10800, "PYT", "PYST", :su, :su, 2, 3, 1970, 3, 8, 0, 0, 0, 1970, 10, 18, 0, 0, 0), # 36
            d.new(-14400, -10800, "FKT", "FKST", :su, :su, 3, 1, 1970, 4, 19, 2, 0, 0, 1970, 9, 6, 2, 0, 0), # 37
            d.new(-14400, -10800, "AST", "ADT", :su, :su, 1, 2, 1970, 11, 1, 0, 1, 0, 1970, 3, 8, 0, 1, 0), # 38
            d.new(-14400, -10800, "AST", "ADT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 39
            d.new(-12600, -9000, "NST", "NDT", :su, :su, 1, 2, 1970, 11, 1, 0, 1, 0, 1970, 3, 8, 0, 1, 0), # 40
            s.new(-10800, "SRT"), # 41
            s.new(-10800, "ART"), # 42
            s.new(-10800, "GFT"), # 43
            s.new(-10800, "ROTT"), # 44
            s.new(-10800, "BRT"), # 45
            d.new(-10800, -7200, "BRT", "BRST", :su, :su, -1, 1, 1970, 2, 22, 0, 0, 0, 1970, 11, 1, 0, 0, 0), # 46
            d.new(-10800, -7200, "UYT", "UYST", :su, :su, 2, 1, 1970, 3, 8, 2, 0, 0, 1970, 10, 4, 2, 0, 0), # 47
            d.new(-10800, -7200, "WGT", "WGST", :sa, :sa, -1, -1, 1970, 10, 24, 23, 0, 0, 1970, 3, 28, 22, 0, 0), # 48
            d.new(-10800, -7200, "PMST", "PMDT", :su, :su, 1, 2, 1970, 11, 1, 2, 0, 0, 1970, 3, 8, 2, 0, 0), # 49
            s.new(-7200, "FNT"), # 50
            s.new(-7200, "GST"), # 51
            s.new(-3600, "CVT"), # 52
            d.new(-3600, 0, "AZOT", "AZOST", :su, :su, -1, -1, 1970, 10, 25, 1, 0, 0, 1970, 3, 29, 0, 0, 0), # 53
            d.new(-3600, 0, "EGT", "EGST", :su, :su, -1, -1, 1970, 10, 25, 1, 0, 0, 1970, 3, 29, 0, 0, 0), # 54
            s.new(0, "GMT"), # 55
            s.new(0, "WET"), # 56
            d.new(0, 3600, "GMT", "IST", :su, :su, -1, -1, 1970, 10, 25, 2, 0, 0, 1970, 3, 29, 1, 0, 0), # 57
            d.new(0, 3600, "GMT", "BST", :su, :su, -1, -1, 1970, 10, 25, 2, 0, 0, 1970, 3, 29, 1, 0, 0), # 58
            d.new(0, 3600, "WET", "WEST", :su, :su, -1, -1, 1970, 10, 25, 2, 0, 0, 1970, 3, 29, 1, 0, 0), # 59
            s.new(3600, "WAT"), # 60
            s.new(3600, "CET"), # 61
            d.new(3600, 7200, "WAT", "WAST", :su, :su, 1, 1, 1970, 4, 5, 2, 0, 0, 1970, 9, 6, 2, 0, 0), # 62
            d.new(3600, 7200, "CET", "CEST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 63
            s.new(7200, "EET"), # 64
            s.new(7200, "CAT"), # 65
            s.new(7200, "IST"), # 66
            s.new(7200, "SAST"), # 67
            d.new(7200, 10800, "EET", "EEST", :th, :fr, -1, -1, 1970, 9, 24, 23, 0, 0, 1970, 4, 24, 0, 0, 0), # 68
            d.new(7200, 10800, "EET", "EEST", :su, :su, -1, -1, 1970, 10, 25, 0, 0, 0, 1970, 3, 29, 0, 0, 0), # 69
            d.new(7200, 10800, "EET", "EEST", :su, :fr, 1, -1, 1970, 10, 1, 0, 0, 0, 1970, 3, 27, 0, 0, 0), # 70
            d.new(7200, 10800, "EET", "EEST", :fr, :su, 3, 1, 1970, 10, 16, 0, 0, 0, 1970, 4, 1, 0, 0, 0), # 71
            d.new(7200, 10800, "EET", "EEST", :fr, :th, -1, -1, 1970, 10, 30, 1, 0, 0, 1970, 3, 26, 0, 0, 0), # 72
            d.new(7200, 10800, "EET", "EEST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 73
            d.new(7200, 10800, "EET", "EEST", :su, :su, -1, -1, 1970, 10, 25, 4, 0, 0, 1970, 3, 29, 3, 0, 0), # 74
            s.new(10800, "EAT"), # 75
            s.new(10800, "AST"), # 76
            s.new(10800, "SYOT"), # 77
            d.new(10800, 14400, "VOLT", "VOLST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 78
            d.new(10800, 14400, "MSK", "MSD", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 79
            d.new(10800, 14400, "AST", "ADT", :su, :su, 1, 1, 1970, 10, 1, 4, 0, 0, 1970, 4, 1, 3, 0, 0), # 80
            s.new(12600, "IRST"), # 81
            s.new(14400, "GET"), # 82
            s.new(14400, "SCT"), # 83
            s.new(14400, "MUT"), # 84
            s.new(14400, "GST"), # 85
            s.new(14400, "RET"), # 86
            d.new(14400, 18000, "SAMT", "SAMST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 87
            d.new(14400, 18000, "AMT", "AMST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 88
            d.new(14400, 18000, "AZT", "AZST", :su, :su, -1, -1, 1970, 10, 25, 5, 0, 0, 1970, 3, 29, 4, 0, 0), # 89
            s.new(16200, "AFT"), # 90
            s.new(18000, "PKT"), # 91
            s.new(18000, "AQTT"), # 92
            s.new(18000, "ORAT"), # 93
            s.new(18000, "TJT"), # 94
            s.new(18000, "TMT"), # 95
            s.new(18000, "TFT"), # 96
            s.new(18000, "MVT"), # 97
            s.new(18000, "UZT"), # 98
            d.new(18000, 21600, "YEKT", "YEKST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 99
            s.new(19800, "IST"), # 100
            s.new(20700, "NPT"), # 101
            s.new(21600, "ALMT"), # 102
            s.new(21600, "BDT"), # 103
            s.new(21600, "VOST"), # 104
            s.new(21600, "MAWT"), # 105
            s.new(21600, "IOT"), # 106
            s.new(21600, "QYZT"), # 107
            s.new(21600, "KGT"), # 108
            s.new(21600, "BTT"), # 109
            d.new(21600, 25200, "NOVT", "NOVST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 110
            d.new(21600, 25200, "OMST", "OMSST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 111
            s.new(23400, "MMT"), # 112
            s.new(23400, "CCT"), # 113
            s.new(25200, "CXT"), # 114
            s.new(25200, "HOVT"), # 115
            s.new(25200, "DAVT"), # 116
            s.new(25200, "WIT"), # 117
            s.new(25200, "ICT"), # 118
            d.new(25200, 28800, "KRAT", "KRAST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 119
            s.new(28800, "CIT"), # 120
            s.new(28800, "BNT"), # 121
            s.new(28800, "SGT"), # 122
            s.new(28800, "HKT"), # 123
            s.new(28800, "PHT"), # 124
            s.new(28800, "ULAT"), # 125
            s.new(28800, "WST"), # 126
            s.new(28800, "MYT"), # 127
            s.new(28800, "CST"), # 128
            d.new(28800, 32400, "IRKT", "IRKST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 129
            s.new(31500, "CWST"), # 130
            s.new(32400, "PWT"), # 131
            s.new(32400, "KST"), # 132
            s.new(32400, "TLT"), # 133
            s.new(32400, "EIT"), # 134
            s.new(32400, "CHOT"), # 135
            s.new(32400, "JST"), # 136
            d.new(32400, 36000, "YAKT", "YAKST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 137
            s.new(34200, "CST"), # 138
            d.new(34200, 37800, "CST", "CST", :su, :su, -1, -1, 1970, 3, 29, 2, 0, 0, 1970, 10, 25, 2, 0, 0), # 139
            s.new(36000, "ChST"), # 140
            s.new(36000, "PGT"), # 141
            s.new(36000, "EST"), # 142
            s.new(36000, "DDUT"), # 143
            s.new(36000, "TRUT"), # 144
            d.new(36000, 39600, "EST", "EST", :su, :su, -1, 1, 1970, 3, 29, 2, 0, 0, 1970, 10, 4, 2, 0, 0), # 145
            d.new(36000, 39600, "EST", "EST", :su, :su, -1, -1, 1970, 3, 29, 2, 0, 0, 1970, 10, 25, 2, 0, 0), # 146
            d.new(36000, 39600, "SAKT", "SAKST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 147
            d.new(36000, 39600, "VLAT", "VLAST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 148
            d.new(37800, 39600, "LHST", "LHST", :su, :su, -1, -1, 1970, 3, 29, 2, 0, 0, 1970, 10, 25, 2, 0, 0), # 149
            s.new(39600, "VUT"), # 150
            s.new(39600, "PONT"), # 151
            s.new(39600, "KOST"), # 152
            s.new(39600, "NCT"), # 153
            s.new(39600, "SBT"), # 154
            d.new(39600, 43200, "MAGT", "MAGST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 155
            s.new(41400, "NFT"), # 156
            s.new(43200, "TVT"), # 157
            s.new(43200, "WAKT"), # 158
            s.new(43200, "GILT"), # 159
            s.new(43200, "MHT"), # 160
            s.new(43200, "FJT"), # 161
            s.new(43200, "WFT"), # 162
            s.new(43200, "NRT"), # 163
            d.new(43200, 46800, "NZST", "NZDT", :su, :su, 3, 1, 1970, 3, 15, 3, 0, 0, 1970, 10, 4, 2, 0, 0), # 164
            d.new(43200, 46800, "NZST", "NZDT", :su, :su, 1, -1, 1970, 4, 5, 3, 0, 0, 1970, 9, 27, 2, 0, 0), # 165
            d.new(43200, 46800, "ANAT", "ANAST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 166
            d.new(43200, 46800, "PETT", "PETST", :su, :su, -1, -1, 1970, 10, 25, 3, 0, 0, 1970, 3, 29, 2, 0, 0), # 167
            d.new(45900, 49500, "CHAST", "CHADT", :su, :su, 1, -1, 1970, 4, 5, 3, 45, 0, 1970, 9, 27, 2, 45, 0), # 168
            s.new(46800, "TOT"), # 169
            s.new(46800, "PHOT"), # 170
            s.new(50400, "LINT"), # 171
        ]

        LOCATION_TO_STRUCT = {
            "Africa/Abidjan".freeze => 55,
            "Africa/Accra".freeze => 55,
            "Africa/Addis_Ababa".freeze => 75,
            "Africa/Algiers".freeze => 61,
            "Africa/Asmara".freeze => 75,
            "Africa/Bamako".freeze => 55,
            "Africa/Bangui".freeze => 60,
            "Africa/Banjul".freeze => 55,
            "Africa/Bissau".freeze => 55,
            "Africa/Blantyre".freeze => 65,
            "Africa/Brazzaville".freeze => 60,
            "Africa/Bujumbura".freeze => 65,
            "Africa/Cairo".freeze => 68,
            "Africa/Casablanca".freeze => 56,
            "Africa/Ceuta".freeze => 63,
            "Africa/Conakry".freeze => 55,
            "Africa/Dakar".freeze => 55,
            "Africa/Dar_es_Salaam".freeze => 75,
            "Africa/Djibouti".freeze => 75,
            "Africa/Douala".freeze => 60,
            "Africa/El_Aaiun".freeze => 56,
            "Africa/Freetown".freeze => 55,
            "Africa/Gaborone".freeze => 65,
            "Africa/Harare".freeze => 65,
            "Africa/Johannesburg".freeze => 67,
            "Africa/Kampala".freeze => 75,
            "Africa/Khartoum".freeze => 75,
            "Africa/Kigali".freeze => 65,
            "Africa/Kinshasa".freeze => 60,
            "Africa/Lagos".freeze => 60,
            "Africa/Libreville".freeze => 60,
            "Africa/Lome".freeze => 55,
            "Africa/Luanda".freeze => 60,
            "Africa/Lubumbashi".freeze => 65,
            "Africa/Lusaka".freeze => 65,
            "Africa/Malabo".freeze => 60,
            "Africa/Maputo".freeze => 65,
            "Africa/Maseru".freeze => 67,
            "Africa/Mbabane".freeze => 67,
            "Africa/Mogadishu".freeze => 75,
            "Africa/Monrovia".freeze => 55,
            "Africa/Nairobi".freeze => 75,
            "Africa/Ndjamena".freeze => 60,
            "Africa/Niamey".freeze => 60,
            "Africa/Nouakchott".freeze => 55,
            "Africa/Ouagadougou".freeze => 55,
            "Africa/Porto-Novo".freeze => 60,
            "Africa/Sao_Tome".freeze => 55,
            "Africa/Tripoli".freeze => 64,
            "Africa/Tunis".freeze => 63,
            "Africa/Windhoek".freeze => 62,
            "America/Adak".freeze => 7,
            "America/Anchorage".freeze => 10,
            "America/Anguilla".freeze => 32,
            "America/Antigua".freeze => 32,
            "America/Araguaina".freeze => 45,
            "America/Argentina/Buenos_Aires".freeze => 42,
            "America/Argentina/Catamarca".freeze => 42,
            "America/Argentina/Cordoba".freeze => 42,
            "America/Argentina/Jujuy".freeze => 42,
            "America/Argentina/La_Rioja".freeze => 42,
            "America/Argentina/Mendoza".freeze => 42,
            "America/Argentina/Rio_Gallegos".freeze => 42,
            "America/Argentina/San_Juan".freeze => 42,
            "America/Argentina/Tucuman".freeze => 42,
            "America/Argentina/Ushuaia".freeze => 42,
            "America/Aruba".freeze => 32,
            "America/Asuncion".freeze => 36,
            "America/Atikokan".freeze => 22,
            "America/Bahia".freeze => 45,
            "America/Barbados".freeze => 32,
            "America/Belem".freeze => 45,
            "America/Belize".freeze => 17,
            "America/Blanc-Sablon".freeze => 32,
            "America/Boa_Vista".freeze => 30,
            "America/Bogota".freeze => 26,
            "America/Boise".freeze => 16,
            "America/Cambridge_Bay".freeze => 16,
            "America/Campo_Grande".freeze => 34,
            "America/Cancun".freeze => 20,
            "America/Caracas".freeze => 33,
            "America/Cayenne".freeze => 43,
            "America/Cayman".freeze => 22,
            "America/Chicago".freeze => 21,
            "America/Chihuahua".freeze => 15,
            "America/Costa_Rica".freeze => 17,
            "America/Cuiaba".freeze => 34,
            "America/Curacao".freeze => 32,
            "America/Danmarkshavn".freeze => 55,
            "America/Dawson".freeze => 13,
            "America/Dawson_Creek".freeze => 14,
            "America/Denver".freeze => 16,
            "America/Detroit".freeze => 28,
            "America/Dominica".freeze => 32,
            "America/Edmonton".freeze => 16,
            "America/Eirunepe".freeze => 25,
            "America/El_Salvador".freeze => 17,
            "America/Fortaleza".freeze => 45,
            "America/Glace_Bay".freeze => 39,
            "America/Godthab".freeze => 48,
            "America/Goose_Bay".freeze => 38,
            "America/Grand_Turk".freeze => 28,
            "America/Grenada".freeze => 32,
            "America/Guadeloupe".freeze => 32,
            "America/Guatemala".freeze => 17,
            "America/Guayaquil".freeze => 24,
            "America/Guyana".freeze => 29,
            "America/Halifax".freeze => 39,
            "America/Havana".freeze => 27,
            "America/Hermosillo".freeze => 14,
            "America/Indiana/Indianapolis".freeze => 28,
            "America/Indiana/Knox".freeze => 21,
            "America/Indiana/Marengo".freeze => 28,
            "America/Indiana/Petersburg".freeze => 21,
            "America/Indiana/Vevay".freeze => 28,
            "America/Indiana/Vincennes".freeze => 21,
            "America/Indiana/Winamac".freeze => 28,
            "America/Inuvik".freeze => 16,
            "America/Iqaluit".freeze => 28,
            "America/Jamaica".freeze => 22,
            "America/Juneau".freeze => 10,
            "America/Kentucky/Louisville".freeze => 28,
            "America/Kentucky/Monticello".freeze => 28,
            "America/La_Paz".freeze => 31,
            "America/Lima".freeze => 23,
            "America/Los_Angeles".freeze => 13,
            "America/Maceio".freeze => 45,
            "America/Managua".freeze => 17,
            "America/Manaus".freeze => 30,
            "America/Martinique".freeze => 32,
            "America/Mazatlan".freeze => 15,
            "America/Menominee".freeze => 21,
            "America/Merida".freeze => 20,
            "America/Mexico_City".freeze => 20,
            "America/Miquelon".freeze => 49,
            "America/Moncton".freeze => 39,
            "America/Monterrey".freeze => 20,
            "America/Montevideo".freeze => 47,
            "America/Montreal".freeze => 28,
            "America/Montserrat".freeze => 32,
            "America/Nassau".freeze => 28,
            "America/New_York".freeze => 28,
            "America/Nipigon".freeze => 28,
            "America/Nome".freeze => 10,
            "America/Noronha".freeze => 50,
            "America/North_Dakota/Center".freeze => 21,
            "America/North_Dakota/New_Salem".freeze => 21,
            "America/Panama".freeze => 22,
            "America/Pangnirtung".freeze => 28,
            "America/Paramaribo".freeze => 41,
            "America/Phoenix".freeze => 14,
            "America/Port-au-Prince".freeze => 22,
            "America/Port_of_Spain".freeze => 32,
            "America/Porto_Velho".freeze => 30,
            "America/Puerto_Rico".freeze => 32,
            "America/Rainy_River".freeze => 21,
            "America/Rankin_Inlet".freeze => 21,
            "America/Recife".freeze => 45,
            "America/Regina".freeze => 17,
            "America/Resolute".freeze => 22,
            "America/Rio_Branco".freeze => 25,
            "America/Santiago".freeze => 35,
            "America/Santo_Domingo".freeze => 32,
            "America/Sao_Paulo".freeze => 46,
            "America/Scoresbysund".freeze => 54,
            "America/Shiprock".freeze => 16,
            "America/St_Johns".freeze => 40,
            "America/St_Kitts".freeze => 32,
            "America/St_Lucia".freeze => 32,
            "America/St_Thomas".freeze => 32,
            "America/St_Vincent".freeze => 32,
            "America/Swift_Current".freeze => 17,
            "America/Tegucigalpa".freeze => 17,
            "America/Thule".freeze => 39,
            "America/Thunder_Bay".freeze => 28,
            "America/Tijuana".freeze => 12,
            "America/Toronto".freeze => 28,
            "America/Tortola".freeze => 32,
            "America/Vancouver".freeze => 13,
            "America/Whitehorse".freeze => 13,
            "America/Winnipeg".freeze => 21,
            "America/Yakutat".freeze => 10,
            "America/Yellowknife".freeze => 16,
            "Antarctica/Casey".freeze => 126,
            "Antarctica/Davis".freeze => 116,
            "Antarctica/DumontDUrville".freeze => 143,
            "Antarctica/Mawson".freeze => 105,
            "Antarctica/McMurdo".freeze => 164,
            "Antarctica/Palmer".freeze => 35,
            "Antarctica/Rothera".freeze => 44,
            "Antarctica/South_Pole".freeze => 164,
            "Antarctica/Syowa".freeze => 77,
            "Antarctica/Vostok".freeze => 104,
            "Arctic/Longyearbyen".freeze => 63,
            "Asia/Aden".freeze => 76,
            "Asia/Almaty".freeze => 102,
            "Asia/Amman".freeze => 72,
            "Asia/Anadyr".freeze => 166,
            "Asia/Aqtau".freeze => 92,
            "Asia/Aqtobe".freeze => 92,
            "Asia/Ashgabat".freeze => 95,
            "Asia/Baghdad".freeze => 80,
            "Asia/Bahrain".freeze => 76,
            "Asia/Baku".freeze => 89,
            "Asia/Bangkok".freeze => 118,
            "Asia/Beirut".freeze => 69,
            "Asia/Bishkek".freeze => 108,
            "Asia/Brunei".freeze => 121,
            "Asia/Calcutta".freeze => 100,
            "Asia/Choibalsan".freeze => 135,
            "Asia/Chongqing".freeze => 128,
            "Asia/Colombo".freeze => 100,
            "Asia/Damascus".freeze => 70,
            "Asia/Dhaka".freeze => 103,
            "Asia/Dili".freeze => 133,
            "Asia/Dubai".freeze => 85,
            "Asia/Dushanbe".freeze => 94,
            "Asia/Gaza".freeze => 71,
            "Asia/Harbin".freeze => 128,
            "Asia/Hong_Kong".freeze => 123,
            "Asia/Hovd".freeze => 115,
            "Asia/Irkutsk".freeze => 129,
            "Asia/Istanbul".freeze => 74,
            "Asia/Jakarta".freeze => 117,
            "Asia/Jayapura".freeze => 134,
            "Asia/Jerusalem".freeze => 66,
            "Asia/Kabul".freeze => 90,
            "Asia/Kamchatka".freeze => 167,
            "Asia/Karachi".freeze => 91,
            "Asia/Kashgar".freeze => 128,
            "Asia/Katmandu".freeze => 101,
            "Asia/Krasnoyarsk".freeze => 119,
            "Asia/Kuala_Lumpur".freeze => 127,
            "Asia/Kuching".freeze => 127,
            "Asia/Kuwait".freeze => 76,
            "Asia/Macau".freeze => 128,
            "Asia/Magadan".freeze => 155,
            "Asia/Makassar".freeze => 120,
            "Asia/Manila".freeze => 124,
            "Asia/Muscat".freeze => 85,
            "Asia/Nicosia".freeze => 74,
            "Asia/Novosibirsk".freeze => 110,
            "Asia/Omsk".freeze => 111,
            "Asia/Oral".freeze => 93,
            "Asia/Phnom_Penh".freeze => 118,
            "Asia/Pontianak".freeze => 117,
            "Asia/Pyongyang".freeze => 132,
            "Asia/Qatar".freeze => 76,
            "Asia/Qyzylorda".freeze => 107,
            "Asia/Rangoon".freeze => 112,
            "Asia/Riyadh".freeze => 76,
            "Asia/Saigon".freeze => 118,
            "Asia/Sakhalin".freeze => 147,
            "Asia/Samarkand".freeze => 98,
            "Asia/Seoul".freeze => 132,
            "Asia/Shanghai".freeze => 128,
            "Asia/Singapore".freeze => 122,
            "Asia/Taipei".freeze => 128,
            "Asia/Tashkent".freeze => 98,
            "Asia/Tbilisi".freeze => 82,
            "Asia/Tehran".freeze => 81,
            "Asia/Thimphu".freeze => 109,
            "Asia/Tokyo".freeze => 136,
            "Asia/Ulaanbaatar".freeze => 125,
            "Asia/Urumqi".freeze => 128,
            "Asia/Vientiane".freeze => 118,
            "Asia/Vladivostok".freeze => 148,
            "Asia/Yakutsk".freeze => 137,
            "Asia/Yekaterinburg".freeze => 99,
            "Asia/Yerevan".freeze => 88,
            "Atlantic/Azores".freeze => 53,
            "Atlantic/Bermuda".freeze => 39,
            "Atlantic/Canary".freeze => 59,
            "Atlantic/Cape_Verde".freeze => 52,
            "Atlantic/Faroe".freeze => 59,
            "Atlantic/Jan_Mayen".freeze => 63,
            "Atlantic/Madeira".freeze => 59,
            "Atlantic/Reykjavik".freeze => 55,
            "Atlantic/South_Georgia".freeze => 51,
            "Atlantic/St_Helena".freeze => 55,
            "Atlantic/Stanley".freeze => 37,
            "Australia/Adelaide".freeze => 139,
            "Australia/Brisbane".freeze => 142,
            "Australia/Broken_Hill".freeze => 139,
            "Australia/Currie".freeze => 145,
            "Australia/Darwin".freeze => 138,
            "Australia/Eucla".freeze => 130,
            "Australia/Hobart".freeze => 145,
            "Australia/Lindeman".freeze => 142,
            "Australia/Lord_Howe".freeze => 149,
            "Australia/Melbourne".freeze => 146,
            "Australia/Perth".freeze => 126,
            "Australia/Sydney".freeze => 146,
            "Europe/Amsterdam".freeze => 63,
            "Europe/Andorra".freeze => 63,
            "Europe/Athens".freeze => 74,
            "Europe/Belgrade".freeze => 63,
            "Europe/Berlin".freeze => 63,
            "Europe/Bratislava".freeze => 63,
            "Europe/Brussels".freeze => 63,
            "Europe/Bucharest".freeze => 74,
            "Europe/Budapest".freeze => 63,
            "Europe/Chisinau".freeze => 74,
            "Europe/Copenhagen".freeze => 63,
            "Europe/Dublin".freeze => 57,
            "Europe/Gibraltar".freeze => 63,
            "Europe/Guernsey".freeze => 58,
            "Europe/Helsinki".freeze => 74,
            "Europe/Isle_of_Man".freeze => 58,
            "Europe/Istanbul".freeze => 74,
            "Europe/Jersey".freeze => 58,
            "Europe/Kaliningrad".freeze => 73,
            "Europe/Kiev".freeze => 74,
            "Europe/Lisbon".freeze => 59,
            "Europe/Ljubljana".freeze => 63,
            "Europe/London".freeze => 58,
            "Europe/Luxembourg".freeze => 63,
            "Europe/Madrid".freeze => 63,
            "Europe/Malta".freeze => 63,
            "Europe/Mariehamn".freeze => 74,
            "Europe/Minsk".freeze => 73,
            "Europe/Monaco".freeze => 63,
            "Europe/Moscow".freeze => 79,
            "Europe/Nicosia".freeze => 74,
            "Europe/Oslo".freeze => 63,
            "Europe/Paris".freeze => 63,
            "Europe/Podgorica".freeze => 63,
            "Europe/Prague".freeze => 63,
            "Europe/Riga".freeze => 74,
            "Europe/Rome".freeze => 63,
            "Europe/Samara".freeze => 87,
            "Europe/San_Marino".freeze => 63,
            "Europe/Sarajevo".freeze => 63,
            "Europe/Simferopol".freeze => 74,
            "Europe/Skopje".freeze => 63,
            "Europe/Sofia".freeze => 74,
            "Europe/Stockholm".freeze => 63,
            "Europe/Tallinn".freeze => 74,
            "Europe/Tirane".freeze => 63,
            "Europe/Uzhgorod".freeze => 74,
            "Europe/Vaduz".freeze => 63,
            "Europe/Vatican".freeze => 63,
            "Europe/Vienna".freeze => 63,
            "Europe/Vilnius".freeze => 74,
            "Europe/Volgograd".freeze => 78,
            "Europe/Warsaw".freeze => 63,
            "Europe/Zagreb".freeze => 63,
            "Europe/Zaporozhye".freeze => 74,
            "Europe/Zurich".freeze => 63,
            "Indian/Antananarivo".freeze => 75,
            "Indian/Chagos".freeze => 106,
            "Indian/Christmas".freeze => 114,
            "Indian/Cocos".freeze => 113,
            "Indian/Comoro".freeze => 75,
            "Indian/Kerguelen".freeze => 96,
            "Indian/Mahe".freeze => 83,
            "Indian/Maldives".freeze => 97,
            "Indian/Mauritius".freeze => 84,
            "Indian/Mayotte".freeze => 75,
            "Indian/Reunion".freeze => 86,
            "Pacific/Apia".freeze => 1,
            "Pacific/Auckland".freeze => 165,
            "Pacific/Chatham".freeze => 168,
            "Pacific/Easter".freeze => 19,
            "Pacific/Efate".freeze => 150,
            "Pacific/Enderbury".freeze => 170,
            "Pacific/Fakaofo".freeze => 3,
            "Pacific/Fiji".freeze => 161,
            "Pacific/Funafuti".freeze => 157,
            "Pacific/Galapagos".freeze => 18,
            "Pacific/Gambier".freeze => 9,
            "Pacific/Guadalcanal".freeze => 154,
            "Pacific/Guam".freeze => 140,
            "Pacific/Honolulu".freeze => 5,
            "Pacific/Johnston".freeze => 5,
            "Pacific/Kiritimati".freeze => 171,
            "Pacific/Kosrae".freeze => 152,
            "Pacific/Kwajalein".freeze => 160,
            "Pacific/Majuro".freeze => 160,
            "Pacific/Marquesas".freeze => 8,
            "Pacific/Midway".freeze => 2,
            "Pacific/Nauru".freeze => 163,
            "Pacific/Niue".freeze => 0,
            "Pacific/Norfolk".freeze => 156,
            "Pacific/Noumea".freeze => 153,
            "Pacific/Pago_Pago".freeze => 2,
            "Pacific/Palau".freeze => 131,
            "Pacific/Pitcairn".freeze => 11,
            "Pacific/Ponape".freeze => 151,
            "Pacific/Port_Moresby".freeze => 141,
            "Pacific/Rarotonga".freeze => 4,
            "Pacific/Saipan".freeze => 140,
            "Pacific/Tahiti".freeze => 6,
            "Pacific/Tarawa".freeze => 159,
            "Pacific/Tongatapu".freeze => 169,
            "Pacific/Truk".freeze => 144,
            "Pacific/Wake".freeze => 158,
            "Pacific/Wallis".freeze => 162,
        }

        s = STRUCT_TO_LOCATION = {}
        LOCATION_TO_STRUCT.each {|l, i| (s[i] ||= []) << l}

        # "st_offset" or "st_offset dl_offset st_month st_hour st_min st_sec dl_month dl_hour dl_min dl_sec"
        #
        OFFSET_TO_STRUCT = {
            "-39600".freeze => 0..2,
            "-36000".freeze => 3..6,
            "-36000 -32400 11 2 0 0 3 2 0 0".freeze => 7..7,
            "-34200".freeze => 8..8,
            "-32400".freeze => 9..9,
            "-32400 -28800 11 2 0 0 3 2 0 0".freeze => 10..10,
            "-28800".freeze => 11..11,
            "-28800 -25200 10 2 0 0 4 2 0 0".freeze => 12..12,
            "-28800 -25200 11 2 0 0 3 2 0 0".freeze => 13..13,
            "-25200".freeze => 14..14,
            "-25200 -21600 10 2 0 0 4 2 0 0".freeze => 15..15,
            "-25200 -21600 11 2 0 0 3 2 0 0".freeze => 16..16,
            "-21600".freeze => 17..18,
            "-21600 -18000 3 22 0 0 10 22 0 0".freeze => 19..19,
            "-21600 -18000 10 2 0 0 4 2 0 0".freeze => 20..20,
            "-21600 -18000 11 2 0 0 3 2 0 0".freeze => 21..21,
            "-18000".freeze => 22..26,
            "-18000 -14400 11 1 0 0 3 0 0 0".freeze => 27..27,
            "-18000 -14400 11 2 0 0 3 2 0 0".freeze => 28..28,
            "-14400".freeze => 29..33,
            "-14400 -10800 2 0 0 0 11 0 0 0".freeze => 34..34,
            "-14400 -10800 3 0 0 0 10 0 0 0".freeze => 35..36,
            "-14400 -10800 4 2 0 0 9 2 0 0".freeze => 37..37,
            "-14400 -10800 11 0 1 0 3 0 1 0".freeze => 38..38,
            "-14400 -10800 11 2 0 0 3 2 0 0".freeze => 39..39,
            "-12600 -9000 11 0 1 0 3 0 1 0".freeze => 40..40,
            "-10800".freeze => 41..45,
            "-10800 -7200 2 0 0 0 11 0 0 0".freeze => 46..46,
            "-10800 -7200 3 2 0 0 10 2 0 0".freeze => 47..47,
            "-10800 -7200 10 23 0 0 3 22 0 0".freeze => 48..48,
            "-10800 -7200 11 2 0 0 3 2 0 0".freeze => 49..49,
            "-7200".freeze => 50..51,
            "-3600".freeze => 52..52,
            "-3600 0 10 1 0 0 3 0 0 0".freeze => 53..54,
            "0".freeze => 55..56,
            "0 3600 10 2 0 0 3 1 0 0".freeze => 57..59,
            "3600".freeze => 60..61,
            "3600 7200 4 2 0 0 9 2 0 0".freeze => 62..62,
            "3600 7200 10 3 0 0 3 2 0 0".freeze => 63..63,
            "7200".freeze => 64..67,
            "7200 10800 9 23 0 0 4 0 0 0".freeze => 68..68,
            "7200 10800 10 0 0 0 3 0 0 0".freeze => 69..70,
            "7200 10800 10 0 0 0 4 0 0 0".freeze => 71..71,
            "7200 10800 10 1 0 0 3 0 0 0".freeze => 72..72,
            "7200 10800 10 3 0 0 3 2 0 0".freeze => 73..73,
            "7200 10800 10 4 0 0 3 3 0 0".freeze => 74..74,
            "10800".freeze => 75..77,
            "10800 14400 10 3 0 0 3 2 0 0".freeze => 78..79,
            "10800 14400 10 4 0 0 4 3 0 0".freeze => 80..80,
            "12600".freeze => 81..81,
            "14400".freeze => 82..86,
            "14400 18000 10 3 0 0 3 2 0 0".freeze => 87..88,
            "14400 18000 10 5 0 0 3 4 0 0".freeze => 89..89,
            "16200".freeze => 90..90,
            "18000".freeze => 91..98,
            "18000 21600 10 3 0 0 3 2 0 0".freeze => 99..99,
            "19800".freeze => 100..100,
            "20700".freeze => 101..101,
            "21600".freeze => 102..109,
            "21600 25200 10 3 0 0 3 2 0 0".freeze => 110..111,
            "23400".freeze => 112..113,
            "25200".freeze => 114..118,
            "25200 28800 10 3 0 0 3 2 0 0".freeze => 119..119,
            "28800".freeze => 120..128,
            "28800 32400 10 3 0 0 3 2 0 0".freeze => 129..129,
            "31500".freeze => 130..130,
            "32400".freeze => 131..136,
            "32400 36000 10 3 0 0 3 2 0 0".freeze => 137..137,
            "34200".freeze => 138..138,
            "34200 37800 3 2 0 0 10 2 0 0".freeze => 139..139,
            "36000".freeze => 140..144,
            "36000 39600 3 2 0 0 10 2 0 0".freeze => 145..146,
            "36000 39600 10 3 0 0 3 2 0 0".freeze => 147..148,
            "37800 39600 3 2 0 0 10 2 0 0".freeze => 149..149,
            "39600".freeze => 150..154,
            "39600 43200 10 3 0 0 3 2 0 0".freeze => 155..155,
            "41400".freeze => 156..156,
            "43200".freeze => 157..163,
            "43200 46800 3 3 0 0 10 2 0 0".freeze => 164..164,
            "43200 46800 4 3 0 0 9 2 0 0".freeze => 165..165,
            "43200 46800 10 3 0 0 3 2 0 0".freeze => 166..167,
            "45900 49500 4 3 45 0 9 2 45 0".freeze => 168..168,
            "46800".freeze => 169..170,
            "50400".freeze => 171..171,
        }
        ## GENERATED-END ##
    end
end

