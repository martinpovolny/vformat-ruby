#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
require 'vformat'

module VFormat
        
    #
    # vCalendar
    #

    class VCALENDAR10 < VersionedComponent
        default_name   'VCALENDAR'

        # atributy by mely byt ve vCalendar umisteny pred subkomponentama
        #
        def_attribute 'DAYLIGHT', :text_list
        def_attribute 'GEO',      :geo
        def_attribute 'PRODID',   :text
        def_attribute 'TZ',       :utc_offset
    end


    # Spolecne atributy a metody trid VEVENT10 a VTODO10
    #
    class CalComponent10 < Component
        def_attribute 'AALARM',         BINARY_OR_URL_OR_CID
        def_attribute 'ATTACH',         BINARY_OR_URL_OR_CID, :multiple => true
        def_attribute 'ATTENDEE',       [:text, :url, :cid],  :multiple => true
        def_attribute 'CATEGORIES',     :text_list
        def_attribute 'CLASS',          :text
        def_attribute 'DALARM',         :text_list
        def_attribute 'DCREATED',       :date_time,           :converter => :convert_time
        def_attribute 'DESCRIPTION',    :text
        def_attribute 'DTSTART',        :date_time,           :converter => :convert_time
        def_attribute 'EXDATE',         :date_time_list,      :converter => :convert_time_list
        def_attribute 'EXRULE',         :recur
        def_attribute 'LAST-MODIFIED',  :date_time # must be in a UTC format (iCal 2.0)
        def_attribute 'LOCATION',       [:text, :url, :cid]
        def_attribute 'MALARM',         [:text_list, :url, :cid]
        def_attribute 'PALARM',         [:text_list, :url, :cid]
        def_attribute 'PRIORITY',       :integer # 0 - znamena to same, jako nespecifikovana priorita
        def_attribute 'RELATED-TO',     :text
        def_attribute 'RDATE',          :date_time_list,      :converter => :convert_time_list
        def_attribute 'RESOURCES',      :text_list
        def_attribute 'RNUM',           :integer
        def_attribute 'RRULE',          :recur
        def_attribute 'SEQUENCE',       :integer # default is 0
        def_attribute 'STATUS',         :text,                :converter => :convert_status
        def_attribute 'SUMMARY',        :text
        def_attribute 'TRANSP',         :integer # TODO koverze na VEVENT20
        def_attribute 'UID',            :text # required (iCal 2.0)
        def_attribute 'URL',            :uri

        #attribute_converter 'DURATION', :convert_duration
    end


    class VEVENT10 < CalComponent10
        default_name  'VEVENT'

        def_attribute 'DTEND', :date_time, :converter => :convert_time
    end


    class VTODO10 < CalComponent10
        default_name  'VTODO'

        def_attribute 'COMPLETED', :date_time, :converter => :convert_time
        def_attribute 'DUE',       :date_time, :converter => :convert_time
    end


    #
    # iCalendar
    #

    class VCALENDAR20 < VersionedComponent
        default_name  'VCALENDAR'

        def_attribute 'CALSCALE', :text
        def_attribute 'METHOD',   :text
        def_attribute 'PRODID',   :text # required
    end


    # Spolecne atributy a metody trid VEVENT20, VTODO20, ...
    #
    class CalComponent20 < CalComponent10
        undef_attribute 'AALARM'
        undef_attribute 'DALARM'
        undef_attribute 'DCREATED'
        undef_attribute 'MALARM'
        undef_attribute 'PALARM'
        undef_attribute 'RNUM'

        def_attribute 'ATTACH',        [:uri, :binary],         :multiple => true
        def_attribute 'ATTENDEE',      :uri,                    :multiple => true  # cal-address
        def_attribute 'CATEGORIES',    :text_list,              :multiple => true
        def_attribute 'COMMENT',       :text,                   :multiple => true
        def_attribute 'CONTACT',       :text,                   :multiple => true
        def_attribute 'CREATED',       :date_time # must be in a UTC format
        def_attribute 'DTSTAMP',       :date_time # must be in a UTC format

        # When used with a recurrence rule, the "DTSTART" and "DTEND" properties
        # MUST be specified in local time and the appropriate set of "VTIMEZONE"
        # calendar components MUST be included.
        #
        def_attribute 'DTSTART',       DATE_TIME_OR_DATE # :required in VEVENT
        def_attribute 'DURATION',      :duration
        def_attribute 'EXDATE',        [:date_time_list, :date_list], :multiple => true
        def_attribute 'EXRULE',        :recur,                        :multiple => true
        def_attribute 'GEO',           :geo
        def_attribute 'LOCATION',      :text
        def_attribute 'ORGANIZER',     :uri # cal-address
        def_attribute 'RDATE',         [:date_time_list, :date_list, :period_list], :multiple => true
        def_attribute 'RECURRENCE-ID', DATE_TIME_OR_DATE
        def_attribute 'RELATED-TO',    :text,                   :multiple => true
        def_attribute 'REQUEST-STATUS',:structured,             :multiple => true
        def_attribute 'RESOURCES',     :text_list,              :multiple => true
        def_attribute 'RRULE',         :recur,                  :multiple => true
    end


    class VEVENT20 < CalComponent20
        default_name  'VEVENT'

        def_attribute 'TRANSP', :text
        def_attribute 'DTEND',  DATE_TIME_OR_DATE
    end


    class VTODO20 < CalComponent20
        default_name  'VTODO'

        #  A "VTODO" calendar component without the "DTSTART" and "DUE" (or
        #  "DURATION") properties specifies a to-do that will be associated with
        #  each successive calendar date, until it is completed.
        #
        def_attribute 'COMPLETED',        :date_time # must be in a UTC format
        def_attribute 'PERCENT-COMPLETE', :integer
        def_attribute 'DUE',              DATE_TIME_OR_DATE, :converter => :convert_due
    end


    class VALARM20 < Component
        default_name 'VALARM'

        def_attribute 'ACTION',       :text  # required
        def_attribute 'ATTENDEE',     :uri, :multiple => true # cal-address
        def_attribute 'TRIGGER',      [:duration, :date_time] # required, date_time must be in a UTC format
        def_attribute 'DESCRIPTION',  :text
        def_attribute 'SUMMARY',      :text
        def_attribute 'ATTACH',       [:uri, :binary]

        # 'duration' and 'repeat' are both optional, and MUST NOT occur more
        # than once each, but if one occurs, so MUST the other
        #
        def_attribute 'DURATION',   :duration
        def_attribute 'REPEAT',     :integer # default is "0"
    end


    class VTIMEZONE20 < Component
        default_name 'VTIMEZONE'

        def_attribute 'TZID',            :text # required
        def_attribute 'LAST-MODIFIED',   :date_time # must be in a UTC format
        def_attribute 'TZURL',           :uri
    end


    class STANDARD20 < Component
        default_name 'STANDARD'

        def_attribute 'COMMENT',       :text,   :multiple => true
        def_attribute 'DTSTART',       DATE_TIME_OR_DATE # required, must be floating format
        def_attribute 'RDATE',         [:date_time_list, :date_list, :period_list], :multiple => true
        def_attribute 'RRULE',         :recur,  :multiple => true
        def_attribute 'TZNAME',        :text,   :multiple => true
        def_attribute 'TZOFFSETFROM',  :utc_offset # required
        def_attribute 'TZOFFSETTO',    :utc_offset # required
    end


    class DAYLIGHT20 < STANDARD20
        default_name 'DAYLIGHT'
    end


    #
    # Methods
    #


    class VCALENDAR10
        # Vrati +VFormat::ZoneInfo::StStruct+ nebo +VFormat::ZoneInfo::StDlStruct+, nebo nil
        # (jestlize z TZ a DAYLIGHT atributu nelze potrebne informace ziskat).
        # 
        def to_zoneinfo_struct
            require 'vformat/zoneinfo'

            self['TZ'].with_value do |tz|
                daylight = self['DAYLIGHT'].value
                dt_class = @encoder.value_type_class(:date_time)

                if daylight and 
                   daylight.size >= 4 and 
                   daylight[0].upcase == 'TRUE' and
                   dl_offset  = (@encoder.value_type_class(:utc_offset).new(daylight[1]).to_i rescue nil) and
                   st_dtstart = (dt_class.new(daylight[3]) rescue nil) and
                   dl_dtstart = (dt_class.new(daylight[2]) rescue nil) and
                   st_dtstart.type == :date_time and
                   dl_dtstart.type == :date_time

                    struct = ZoneInfo::StDlStruct.new
                    struct.st_name   = daylight[4] unless daylight[4].to_s.empty?
                    struct.dl_name   = daylight[5] unless daylight[5].to_s.empty?
                    struct.st_wday   = st_dtstart.wday
                    struct.dl_wday   = dl_dtstart.wday
                    struct.dl_offset = dl_offset
                    struct.set_st_from_date_time(st_dtstart)
                    struct.set_dl_from_date_time(dl_dtstart)
                else
                    struct = ZoneInfo::StStruct.new
                end

                struct.st_offset = tz.to_i
                struct
            end
        end

        # Prida TZ a DAYLIGHT atributy podle timezony zadane pomoci
        # +VFormat::ZoneInfo::StStruct+ nebo +VFormat::ZoneInfo::StDlStruct+.
        # 
        def add_timezone_for_struct(struct)
            add('TZ', struct.st_offset)

            if struct.has_dl?
                dt_class = @encoder.value_type_class(:date_time)
                add(
                    'DAYLIGHT', 
                    [
                        'TRUE',
                        @encoder.value_type_class(:utc_offset).new(struct.dl_offset).encode(@encoder),
                        dt_class.new(struct.dl_date_time_a).encode(@encoder),
                        dt_class.new(struct.st_date_time_a).encode(@encoder),
                        struct.st_name.to_s,
                        struct.dl_name.to_s,
                    ]
                )
            end

            self
        end

        # Prida TZ a DAYLIGHT atributy odpovidajici timezone zadane pomoci
        # +location+.
        # 
        def add_timezone(location)
            require 'vformat/zoneinfo'

            raise ArgumentError, "invalid timezone location `#{location}'" unless 
                d = ZoneInfo::LOCATION_TO_STRUCT[location]

            add_timezone_for_struct(ZoneInfo::STRUCTS[d])
        end

        def convert_from(cal) #:nodoc:
            return unless cal.version == '2.0'

            # prevod timezone - vCalendar podporuje jenom jednu timezonu, takze
            # prevedeme prvni v iCalendari a ostatni ignorujeme
            #
            convert_wrap_error do
                if tz = cal.first('VTIMEZONE') and struct = tz.to_zoneinfo_struct
                    add_timezone_for_struct(struct)
                end
            end
        end
    end


    class CalComponent10
        def convert_time(old_comp, atr) #:nodoc:
            convert_attribute(atr, :date_time).params.delete('TZID')
        end

        def convert_time_list(old_comp, atr) #:nodoc:
            raise ConvertError, "unsupported attribute type :#{atr.value_type}" unless
                [:date_time_list, :time_list].include?(atr.value_type)

            convert_attribute(atr, :date_time_list).params.delete('TZID')
        end

        def convert_status(old_comp, atr) #:nodoc:
            new_value = case atr.value
            when "NEEDS-ACTION"
                "NEEDS ACTION"
            when "IN-PROCESS"
                "ACCEPTED"
            when "CONFIRMED", "COMPLETED", "TENTATIVE"  # spolecne hodnoty
                atr.value
            when "NEEDS ACTION", "ACCEPTED", "SENT", "DECLINED", "DELEGATED" # jiz prevedene hodnoty
                atr.value
            else
                # "CANCELLED", "DRAFT", "FINAL"
                #
                raise ConvertError, "unsupported status"
            end

            convert_attribute(atr).value.replace(new_value)
        end

        # TODO
        #def convert_duration(old_comp, atr) #:nodoc:
        #    if dtstart = old_comp['DTSTART'].value and !old_comp.attribute?('DTEND')
        #        add('DTEND', ...)
        #    end
        #end
    end


    class VCALENDAR20

        def timezone(tzid)
            each('VTIMEZONE').find {|t| t['TZID'].value == tzid}
        end

        # Prida VTIMEZONE komponentu odpovidajici timezone zadane pomoci
        # +location+. Viz. +VFormat::VTIMEZONE20.new_for_location+.
        #
        # Vraci novou komponentu.
        # 
        def add_timezone(location, tzid = nil, &block)
            add(@encoder.component('VTIMEZONE').new_for_location(location, tzid, &block))
        end

        def convert_from(cal) #:nodoc:
            return unless cal.version == '1.0'

            # pridani timezone
            #
            convert_wrap_error do
                if struct = cal.to_zoneinfo_struct
                    add(@encoder.component('VTIMEZONE').new_for_struct(struct, 'ConvertedZone'))
                end
            end
        end

        def converted_from(cal) #:nodoc:
            return unless cal.version == '1.0'

            # korekce casu
            #
            if timezone('ConvertedZone')
                each_attribute do |atr, comp|
                    if comp.name == 'VTIMEZONE'
                        :back
                    else
                        case atr.value_type
                        when :date_time
                            atr['TZID'] = 'ConvertedZone' if atr.value.zone.nil?
                                
                        when :date_time_list
                            atr['TZID'] = 'ConvertedZone' if atr.value.find {|d| d.zone.nil?}
                        end
                    end
                end
            end
        end
    end


    class CalComponent20
        def convert_status(old_comp, atr) #:nodoc:
            new_value = case atr.value
            when "NEEDS ACTION"                        
                "NEEDS-ACTION"
            when "ACCEPTED"
                "IN-PROCESS"
            when "CONFIRMED", "COMPLETED", "TENTATIVE" # spolecne hodnoty
                atr.value
            when "NEEDS-ACTION", "IN-PROCESS", "CANCELLED", "DRAFT", "FINAL" # jiz prevedene hodnoty 
                atr.value
            else      
                # "SENT", "DECLINED", "DELEGATED"
                #
                raise ConvertError, "unsupported status"
            end

            convert_attribute(atr).value.replace(new_value)
        end

        def converted_from(cal) #:nodoc:
            return unless cal.version == '1.0'

            dtstart = first('DTSTART')
            dtend   = first('DTEND')

            # vCal 1.0 nemusi obsahovat DTSTART a zaroven muze mit DTEND
            #
            if !dtstart and dtend
                dtstart, dtend = dtend, nil
                dtstart.name = 'DTSTART'
            end

            # prevod z :date_time na :date typ
            #
            if dtstart and dtend and dtstart.value.zero_time? and dtend.value.zero_time?
                dtstart.date = dtstart.value
                dtend.date   = dtend.value
                dtstart.params.delete 'TZID'
                dtend.params.delete 'TZID'
            end
        end
    end


    class VTODO20
        def convert_due(old_comp, atr) #:nodoc:
            if atr.date_time? and atr.value.zero_time?
                # date_time je T000000, prevedeme ho na date
                #
                convert_attribute(atr, :date)
            else
                convert_attribute(atr)
            end
        end
    end


    class VTIMEZONE20
        # one of 'STANDARD' or 'DAYLIGHT' must occur and each may occur more
        # than once.

        # Vrati +VFormat::ZoneInfo::StStruct+ nebo +VFormat::ZoneInfo::StDlStruct+, nebo nil
        # (jestlize z VTIMEZONE nelze potrebne informace ziskat).
        # 
        def to_zoneinfo_struct
            require 'vformat/zoneinfo'

            return nil unless st = each('STANDARD').max do |a, b|
                a['DTSTART'].value.to_s <=> b['DTSTART'].value.to_s
            end

            return nil unless st.attribute?('TZOFFSETTO')

            dl = each('DAYLIGHT').max do |a, b|
                a['DTSTART'].value.to_s <=> b['DTSTART'].value.to_s
            end

            if dl and 
               st_dtstart = st['DTSTART'].value and 
               dl_dtstart = dl['DTSTART'].value and
               st_dtstart.type == :date_time and
               dl_dtstart.type == :date_time and
               dl_rrule = dl['RRULE'].value and
               st_rrule = st['RRULE'].value and
               (   st_rrule.freq == :yearly or
                 ( st_rrule.freq == :monthly and st_rrule.interval == 12 ) ) and
               (   dl_rrule.freq == :yearly or 
                 ( dl_rrule.freq == :monthly and dl_rrule.interval == 12 ) )

                struct = ZoneInfo::StDlStruct.new
                struct.set_st_from_date_time(st_dtstart)
                struct.set_dl_from_date_time(dl_dtstart)

                # informace v RRULE maji prednost
                #
                t = nil
                struct.st_month = t if t = (st_rrule.by_month || []).first
                struct.dl_month = t if t = (dl_rrule.by_month || []).first

                if t = (st_rrule.by_day || []).first and Array === t
                    struct.st_wday_pos, struct.st_wday = t 
                else
                    struct.st_wday = st_dtstart.wday
                end

                if t = (dl_rrule.by_day || []).first and Array === t
                    struct.dl_wday_pos, struct.dl_wday = t 
                else
                    struct.dl_wday = dl_dtstart.wday
                end

                struct.dl_offset = dl['TZOFFSETTO'].value.to_i
                struct.dl_name   = dl['TZNAME'].with_value {|v| v.to_s}
            else
                struct = ZoneInfo::StStruct.new
            end

            struct.st_offset = st['TZOFFSETTO'].value.to_i
            struct.st_name   = st['TZNAME'].with_value {|v| v.to_s}
            struct
        end

        # Vrati novou VTIMEZONE komponentu pro timezonu zadanou pomoci
        # +VFormat::ZoneInfo::StStruct+ nebo +VFormat::ZoneInfo::StDlStruct+.
        #
        # S novou komponentou zavola pripadny predany blok. Jeji TZID je
        # nastaven na +tzid+ a X-LIC-LOCATION na +lic_location+ (je-li
        # zadano).
        # 
        def self.new_for_struct(d, tzid, lic_location = nil)
            tz = new
            tz.add('TZID', tzid)
            tz.add('X-LIC-LOCATION', lic_location) if lic_location

            if d.has_dl?
                tz.add('DAYLIGHT') do |c|
                    c.add('TZOFFSETFROM', d.st_offset)
                    c.add('TZOFFSETTO',   d.dl_offset)
                    c.add('TZNAME',       d.dl_name) if d.dl_name
                    c.add('DTSTART',      d.dl_date_time_a)

                    if d.dl_wday_pos
                        c.add('RRULE',  :freq     => :yearly, 
                                        :interval => 1, 
                                        :by_month => d.dl_month, 
                                        :by_day   => [[d.dl_wday_pos, d.dl_wday]])
                    else
                        c.add('RRULE', :freq => :yearly, :interval => 1)
                    end
                end
                tz.add('STANDARD') do |c|
                    c.add('TZOFFSETFROM', d.dl_offset)
                    c.add('TZOFFSETTO',   d.st_offset)
                    c.add('TZNAME',       d.st_name) if d.st_name
                    c.add('DTSTART',      d.st_date_time_a)

                    if d.st_wday_pos
                        c.add('RRULE',  :freq     => :yearly, 
                                        :interval => 1, 
                                        :by_month => d.st_month, 
                                        :by_day   => [[d.st_wday_pos, d.st_wday]])
                    else
                        c.add('RRULE', :freq => :yearly, :interval => 1)
                    end
                end
            else
                tz.add('STANDARD') do |c|
                    c.add('TZOFFSETFROM', d.st_offset)
                    c.add('TZOFFSETTO',   d.st_offset)
                    c.add('TZNAME',       d.st_name) if d.st_name
                    c.add('DTSTART',      [1970, 1, 1, 0, 0, 0])
                end
            end

            yield(tz) if block_given?
            tz
        end

        # Vrati novou VTIMEZONE komponentu pro zadanou timezonu pomoci
        # +location+.
        #
        # S novou komponentou zavola pripadny predany blok. Jeji TZID je
        # nastaven na +tzid+, nebo na +location+ je-li +tzid+ nil.
        # 
        def self.new_for_location(location, tzid = nil)
            require 'vformat/zoneinfo'

            raise ArgumentError, "invalid timezone location `#{location}'" unless 
                d = ZoneInfo::LOCATION_TO_STRUCT[location]

            new_for_struct(ZoneInfo::STRUCTS[d], tzid || location, location)
        end
    end


    #
    # Values
    #


    module Value
       
        class Recur
            include Mixin

            register :recur

            BY = {
                :by_second   => [:map_range,       0..59],
                :by_minute   => [:map_range,       0..59],
                :by_hour     => [:map_range,       0..23],
                :by_monthday => [:map_negrange,  -31..31],  # != 0
                :by_yearday  => [:map_negrange, -366..366], # != 0
                :by_weekno   => [:map_negrange,  -53..53],  # != 0
                :by_month    => [:map_range,       1..12],
                :by_setpos   => [:map_negrange, -366..366], # != 0
                :by_day      => [:map_wdays],
            }

            BY_ORDER = [
                :by_month,
                :by_weekno,
                :by_yearday,
                :by_monthday,
                :by_day,
                :by_hour,
                :by_minute,
                :by_second,
                :by_setpos,
            ]

            FREQ = {
                :secondly => 0,
                :minutely => 1,
                :hourly   => 2,
                :daily    => 3,
                :weekly   => 4,
                :monthly  => 5,
                :yearly   => 6,
            }

            # [Symbol] viz. +FREQ+
            #
            attr_reader :freq

            def freq=(v)
                v = v.downcase.intern if String === v
                raise ArgumentError, "unknown freq `#{v}'" unless FREQ[v]
                @freq = v
            end

            # [nil | Integer]
            #
            attr_reader :count

            def count=(v)
                if v.nil?
                    @count = nil
                else
                    v = check_posint(v)
                    raise ArgumentError, "count `#{v}' out of range" if v == 0
                    @count = v
                    @until = nil
                end

                v
            end

            # [nil | VFormat::Value::Date | VFormat::Value::DateTime]
            #
            attr_reader :until

            def until=(v)
                case v
                when nil
                    @until = nil
                when String
                    @until = v =~ DATE_REGEXP ? Date.new(v) : DateTime.new(v)
                    @count = nil
                when Array
                    @until = v.size == 3 ? Date.new(v) : DateTime.new(v)
                    @count = nil
                else 
                    @until = v
                    @count = nil
                end

                v
            end

            # [Integer] 
            #
            attr_reader :interval

            def interval=(v)
                v = check_posint(v)
                raise ArgumentError, "interval `#{v}' out of range" if v == 0
                @interval = v
            end

            # [Symbol] mozne hodnoty viz. +VFormat::WEEKDAYS+.
            #
            attr_reader :week_start

            alias :wkst :week_start

            def week_start=(v)
                v = v.downcase.intern if String === v
                raise ArgumentError, "unknown weekday `#{v}'" unless WEEKDAYS.include?(v)
                @week_start = v
            end

            alias :wkst= :week_start=

            # +by_...+ hodnoty jsou pole cisel nebo nil. Pro mozne rozsahy cisel viz. +BY+.
            # +by_day+ hodnota je slozitejsi a muze vypadat napr. takto:
            #    [:tu, [-3, :we]]
            #
            BY.each do |key, map| 
                attr_reader(key)

                eval("def %s=(vals); @%s=vals.nil? ? nil : %s(%p, vals, %p); vals; end" % [
                    key,
                    key,
                    map[0],
                    key.to_s,
                    map[1],
                ])
            end

            def self.decode(str, encoder)
                rule = new

                str.split(';').each do |part|
                    next unless part =~ /\A(FREQ|COUNT|UNTIL|INTERVAL|WKST|BY([A-Z]+))=(.+)\z/

                    if $2
                        # BY...
                        #
                        by, vals = "by_#{$2.downcase}".intern, $3
                        next unless BY[by]

                        rule.send("#{by}=", vals)
                    else
                        rule.send("#{$1.downcase}=", $3)
                    end
                end

                rule
            end

            # Parametr +args+ muze byt nil, +Hash+, +Recur+ nebo +RecurPreRFC+.
            # Konvertor z +RecurPreRFC+ umi prevest pouze omezenou podmnozinu
            # pravidel, takze vysledne +Recur+ pravidlo nemusi generovat shodnou
            # sadu udalosti.
            #
            def initialize(args = nil)
                case args 
                when RecurPreRFC
                    args = args.to_recur_hash
                when Recur
                    args = args.to_hash
                end

                args.to_hash.each {|k, v| send("#{k}=", v)} if args

                @freq        ||= :daily
                @interval    ||= 1
                @count       ||= nil
                @until       ||= nil
                @week_start  ||= :mo

                @by_second   ||= nil
                @by_minute   ||= nil
                @by_hour     ||= nil
                @by_monthday ||= nil
                @by_yearday  ||= nil
                @by_weekno   ||= nil
                @by_month    ||= nil
                @by_setpos   ||= nil
                @by_day      ||= nil
            end

            def encode(encoder = Encoder::RFC2425)
                result = []
                result << "FREQ=#{@freq.to_s.upcase}"
                result << "INTERVAL=#{@interval}" unless @interval == 1
                result << "COUNT=#{@count}" if @count
                result << "UNTIL=#{@until.encode(encoder)}" if @until
                result << "WKST=#{@week_start.to_s.upcase}" unless @week_start == :mo

                BY_ORDER.each do |by|
                    vals = send(by)
                    next if !vals or vals.empty?

                    result << (by.to_s.delete('_').upcase << '=' << join_vals(vals))
                end

                result.join(';')
            end

            def to_s
                encode
            end

            def to_hash
                {
                    :freq        => @freq,
                    :interval    => @interval,
                    :count       => @count,
                    :until       => @until,
                    :week_start  => @week_start,
                                 
                    :by_second   => @by_second,
                    :by_minute   => @by_minute,
                    :by_hour     => @by_hour,
                    :by_monthday => @by_monthday,
                    :by_yearday  => @by_yearday,
                    :by_weekno   => @by_weekno,
                    :by_month    => @by_month,
                    :by_setpos   => @by_setpos,
                    :by_day      => @by_day,
                }
            end

            def to_prerfc_hash
                do_hhmm_list = proc do
                    result = []

                    if @by_minute and !@by_minute.empty?
                        if @by_hour and !@by_hour.empty?
                            @by_hour.each {|h| @by_minute.each {|m| result << ("%02d%02d" % [h, m])}}
                        else
                            24.times {|h| @by_minute.each {|m| result << ("%02d%02d" % [h, m])}}
                        end
                    elsif @by_hour
                        @by_hour.each {|h| result << ("%02d00" % h)}
                    end

                    result
                end

                by_size  = 0
                interval = @interval

                case freq  = @freq
                when :secondly
                    freq = :minutely

                when :hourly
                    # [ "1230", "1330$", ...  ]
                    #
                    freq = :daily
                    by = []
                    0.step(23, @interval) {|h| by << ("%02d00" % h.to_s)}
                    interval = 1
                    by_size = by.size

                when :daily
                    # [ "1230", "1330$", ...  ]
                    #
                    by = do_hhmm_list.call
                    by_size = by.size

                when :weekly
                    # [ "SU", [], "WE", ["1330$", ...], "FR$", [], ... ]
                    #
                    hhmm        = do_hhmm_list.call
                    by_size_add = hhmm.size > 1 ? hhmm.size : 1
                    by          = []

                    (@by_day || []).each do |a|
                        by << (Array === a ? a[1] : a).to_s.upcase
                        by << hhmm.dup
                        by_size += by_size_add
                    end

                when :monthly
                    if @by_day and !@by_day.empty?
                        # [ ["1-$", "2+", ...], ["SU", ...], ["1330$", ...], ["1+"], ["FR$"], [], ... ]
                        #
                        freq = :monthlybypos
                        hhmm = do_hhmm_list.call
                        by   = []

                        @by_day.each do |a|
                            if Array === a
                                by << [a[0] < 0 ? "#{-a[0]}-" : "#{a[0]}+"]
                                by << [a[1].to_s.upcase]
                            else 
                                if @by_setpos and !@by_setpos.empty?
                                    by << @by_setpos.map {|p| p < 0 ? "#{p}-" : "#{p}+"}
                                else
                                    by << ["1+", "2+", "3+", "4+", "5+"]
                                end
                                by << [a.to_s.upcase]
                            end

                            by << hhmm.dup
                            by_size += (hhmm.size > 1 ? hhmm.size : 1) * (by[-3].size > 1 ? by[-3].size : 1)
                        end
                    else
                        # [ "21", "4-", "5+$", 'LD', ... ]
                        #
                        freq = :monthlybyday
                        by   = (@by_monthday || []).map {|d| d < 0 ? "#{d}-" : d.to_s}
                        by_size = by.size
                    end

                when :yearly
                    if @by_yearday and !@by_yearday.empty?
                        # [ "222", "44$", ... ]
                        #
                        freq = :yearlybyday
                        by = @by_yearday.map {|m| m.to_s}
                    else
                        # [ "12", "4", "5$", ... ]
                        #
                        freq = :yearlybymonth
                        by = (@by_month || []).map {|m| m.to_s}
                    end
                    by_size = by.size
                end

                by ||= []

                if count = @count
                    count = (count + by_size - 1) / by_size if by_size > 1
                end

                if @until
                    untl = DateTime.new(@until)
                    # TODO - prevod z Date je blbe; prevest do UTC
                    # ?? untl.zone = 'Z' if Date === @until
                else
                    untl = nil
                end

                {
                    :freq      => freq,
                    :interval  => interval,
                    :count     => count,
                    :until     => untl,
                    :by        => by,
                }
            end

        private

            def join_vals(vals) #:nodoc:
                vals.map do |v|
                    case v
                    when Integer
                        v.to_s
                    when Array
                        "#{v[0]}#{v[1].to_s.upcase}"
                    else
                        v.to_s.upcase
                    end
                end.join(',')
            end

            def split_vals(vals) #:nodoc:
                case vals
                when Array
                    vals
                when String
                    vals.split(',')
                else
                    [vals]
                end
            end

            def map_range(name, vals, range) #:nodoc:
                split_vals(vals).map do |v|
                    v = check_posint(v)
                    raise ArgumentError, "#{name} value `#{v}' out of range" unless
                        range.include?(v)
                    v
                end
            end

            def map_negrange(name, vals, range) #:nodoc:
                split_vals(vals).map do |v|
                    v = check_int(v)
                    raise ArgumentError, "#{name} value `#{v}' out of range" unless
                        range.include?(v) and v != 0
                    v
                end
            end

            def map_wdays(name, vals, none = nil) #:nodoc:
                split_vals(vals).map do |v|
                    if String === v
                        raise ArgumentError, "incorrect #{name} value `#{v}'" unless
                            v =~ /\A([-+]?\d+)?(SU|MO|TU|WE|TH|FR|SA)\z/

                        v = $1 ? [$1.to_i, $2.downcase.intern] : $2.downcase.intern
                    end

                    if Array === v
                        raise ArgumentError, "#{name} value `#{v[0]}' out of range" unless
                            (-53..53).include?(v[0]) and v[0] != 0

                        raise ArgumentError, "unknown weekday `#{v[1]}'" unless WEEKDAYS.include?(v[1])
                    else
                        raise ArgumentError, "unknown weekday `#{v}'" unless WEEKDAYS.include?(v)
                    end
                    v
                end
            end

        end # VFormat::Value::Recur


        class RecurPreRFC
            include Mixin

            register :recur

            FREQ = {
                :minutely      => "M",
                :daily         => "D",
                :weekly        => "W",
                :monthlybypos  => "MP",
                :monthlybyday  => "MD",
                :yearlybymonth => "YM",
                :yearlybyday   => "YD",
            }
            FREQ_I = FREQ.invert


            # [nil | RecurPreRFC] zanorene pravidlo opakovani
            # 
            attr_reader :subrule

            def subrule=(r)
                @subrule = RecurPreRFC === r ? r : RecurPreRFC.new(r)
            end

            # [Symbol] viz. +FREQ+
            #
            attr_reader :freq

            def freq=(v)
                raise ArgumentError, "unknown freq `#{v}'" unless FREQ[v]
                @freq = v
            end

            # [nil | Integer]
            #
            attr_reader :count

            def count=(v)
                if v.nil?
                    @count = nil
                else
                    v = check_posint(v)
                    if v == 0
                        @count = @until = nil
                    else
                        @count = v
                    end
                end
            end

            # [nil | VFormat::Value::DateTime]
            #
            attr_reader :until

            def until=(v)
                case v
                when nil then       @until = v
                when DateTime then  @until = v
                else                @until = DateTime.new(v)
                end
            end

            # [Integer] 
            #
            attr_reader :interval

            def interval=(v)
                v = check_posint(v)
                raise ArgumentError, "interval `#{v}' out of range" if v == 0
                @interval = v
            end

            # [Array of ...] "by" modifikatory. Format se lisi podle frequence:
            #   - minutely: []
            #   - daily: [ "1230", "1330$", ...  ]
            #   - weekly: [ "SU", [], "WE", ["1330$", ...], "FR$", [], ... ]
            #   - monthlybypos: [ ["1-$", "2+", ...], ["SU", ...], ["1330$", ...], ["1+"], ["FR$"], [], ... ]
            #   - monthlybyday: [ "21", "4-", "5+$", 'LD', ... ]
            #   - yearlybymonth: [ "12", "4", "5$", ... ]
            #   - yearlybyday: [ "222", "44$", ... ]
            # 
            attr_accessor :by

            def self.decode(str, encoder)
                root_rule = nil
                rule      = nil
                not_space = /[^\s]+/

                map_timelist = proc do |vals|
                    ret = []
                    if !vals.empty?
                        ret = vals.scan(/\d\d\d\d\$?/)
                        ret.each do |hhmm|
                            raise DecodeError, "hhmm value `#{hhmm}' out of range" unless
                                (0..23).include?(hhmm[0, 2].to_i) and (0..59).include?(hhmm[2, 2].to_i)
                        end
                    end
                    ret
                end

                str.upcase.scan(/
                    \G \s*
                    (
                        M\d+  |
                        D\d+  (?:\s+\d{4}\$?)* |
                        W\d+  (?: \s+ (?:SU|MO|TU|WE|TH|FR|SA)\$? (?:\s+\d{4}\$?)* )* |
                        MP\d+ (?: (?:\s+[1-5][+-]\$?)+ (?:\s+(?:SU|MO|TU|WE|TH|FR|SA)\$?)+ (?:\s+\d{4}\$?)* )* |
                        MD\d+ (?: \s+ (?: \d\d?[+-]?\$? | LD ) )* |
                        YM\d+ (?:\s+\d\d?\$?)* |
                        YD\d+ (?:\s+\d{1,3}\$?)*
                    )
                    (?:\s+\#(\d+))?
                    (?= \s+ [MDWY\d] | \s*\z )
                /xm) do |data, count|
                    if rule
                        rule = (rule.subrule = new)
                        rule.count = count
                    else
                        rule = root_rule = new

                        # count, until
                        # If the duration or and end date is not established in the
                        # rule (e.g. ``D2'') the event occurs twice. That is D2 is
                        # equivalent to D2 #2.
                        #
                        rule.until = (str =~ /\s+(#{DATE_PATTERN}T#{TIME_PATTERN})\s*\z/mo) ? $1 : nil
                        rule.count = (count or rule.until) ? count : 2
                    end

                    a = /\A([A-Z]+)(\d+)(.*)\z/.match(data)

                    # freq
                    #
                    rule.freq = FREQ_I[a[1]]

                    # interval
                    #
                    rule.interval = a[2].to_i

                    # by
                    #
                    case rule.freq
                    when :daily
                        rule.by = map_timelist.call(a[3])

                    when :weekly
                        a[3].scan(/\s+([A-Z]{2}\$?)((?:\s+\d{4}\$?)*)/m) do |w, t|
                            rule.by << w
                            rule.by << map_timelist.call(t)
                        end

                    when :monthlybypos
                        a[3].scan(/((?:\s+[1-5][+-]\$?)+)((?:\s+[A-Z]{2}\$?)+)((?:\s+\d{4}\$?)*)/m) do |p, w, t|
                            rule.by << p.scan(not_space)
                            rule.by << w.scan(not_space)
                            rule.by << map_timelist.call(t)
                        end

                    when :monthlybyday
                        rule.by = a[3].scan(not_space)
                        rule.by.each do |day|
                            raise DecodeError, "day `#{day}' out of range" unless
                                day == 'LD' or (1..31).include?(day.to_i)
                        end
                        
                    when :yearlybymonth
                        rule.by = a[3].scan(not_space)
                        rule.by.each do |month|
                            raise DecodeError, "month `#{month}' out of range" unless
                                (1..12).include?(month.to_i)
                        end
                        
                    when :yearlybyday
                        rule.by = a[3].scan(not_space)
                        rule.by.each do |day|
                            raise DecodeError, "day `#{day}' out of range" unless
                                (1..366).include?(day.to_i)
                        end
                    end
                end

                raise DecodeError, "incorrect rule" unless root_rule

                root_rule
            end

            # Parametr +args+ muze byt nil, +Hash+, +RecurPreRFC+ nebo +Recur+.
            # Konvertor z +Recur+ umi prevest pouze omezenou podmnozinu
            # pravidel, takze vysledne +RecurPreRFC+ pravidlo nemusi generovat
            # shodnou sadu udalosti.
            #
            def initialize(args = nil)
                case args 
                when Recur
                    args = args.to_prerfc_hash
                when RecurPreRFC
                    args = args.to_hash
                end

                args.each {|k, v| send("#{k}=", v)} if args

                @freq        ||= :daily
                @interval    ||= 1
                @count       ||= nil
                @until       ||= nil
                @by          ||= []
                @subrule     ||= nil
            end

            def to_hash
                {
                    :freq     => @freq,
                    :interval => @interval,
                    :count    => @count,
                    :until    => @until,
                    :by       => @by,
                    :subrule  => @subrule ? @subrule.to_hash : nil,
                }
            end

            def to_recur_hash
                count = @count
                by    = {}

                do_hhmm_list = proc do |hhmm_list|
                    # vysledkem muze byt vice udalosti, nez bylo v originalu
                    #
                    unless hhmm_list.empty?
                        by[:by_hour]   ||= []
                        by[:by_minute] ||= []

                        hhmm_list.each do |hhmm|
                            by[:by_hour] << hhmm[0, 2].to_i
                            by[:by_minute] << hhmm[2, 2].to_i
                        end
                    end
                end

                case freq = @freq
                when :daily
                    # [ "1230", "1330$", ...  ]
                    #
                    do_hhmm_list.call(@by)

                when :weekly
                    # [ "SU", [], "WE", ["1330$", ...], "FR$", [], ... ]
                    #
                    by[:by_day] = []

                    @by.each_slice(2) do |d, hhmm|
                        by[:by_day] << d[0, 2].downcase.intern
                        do_hhmm_list.call(hhmm)
                    end

                when :monthlybypos 
                    # [ ["1-$", "2+", ...], ["SU", ...], ["1330$", ...], ["1+"], ["FR$"], [], ... ]
                    #
                    freq = :monthly
                    by[:by_day] = []

                    @by.each_slice(3) do |pos_list, day_list, hhmm|
                        pos_list.each do |p| 
                            i = p.include?('-') ? -(p.to_i) : p.to_i
                            day_list.each {|d| by[:by_day] << [i, d[0, 2].downcase.intern]}
                        end

                        do_hhmm_list.call(hhmm)
                    end

                when :monthlybyday
                    # [ "21", "4-", "5+$", 'LD', ... ]
                    #
                    freq = :monthly

                    by[:by_monthday] = @by.map do |p|
                        if p == 'LD' 
                            -1 
                        else
                            p.include?('-') ? -(p.to_i) : p.to_i
                        end
                    end

                when :yearlybymonth 
                    # [ "12", "4", "5$", ... ]
                    #
                    freq = :yearly
                    by[:by_month] = @by.map {|m| m.to_i}

                when :yearlybyday 
                    # [ "222", "44$", ... ]
                    #
                    freq = :yearly
                    by[:by_yearday] = @by.map {|d| d.to_i}
                end

                by.each_value do |arr|
                    next if arr.empty?
                    arr.uniq!
                    count *= arr.size if count
                end

                by[:freq]      = freq
                by[:interval]  = @interval
                by[:count]     = count

                if count.nil? and @until
                    if @until.zero_time? and !by[:by_hour] and !by[:by_minute]
                        # vypada to, ze je mozne z DateTime udelat Date
                        #
                        by[:until] = Date.new(@until)
                    else
                        by[:until] = @until.copy # TODO - prevest do UTC
                    end
                else
                    by[:until] = nil
                end

                by
            end

            def encode(encoder = Encoder::RFC2425)
                result = []
                rule = self

                while rule
                    result << "#{FREQ[rule.freq]}#{rule.interval}"
                    result.concat(rule.by)

                    if rule.count
                        result << "##{rule.count}"
                    elsif rule == self and @until.nil?
                        result << "#0"
                    end

                    rule = rule.subrule
                end

                result << @until.encode(encoder) if @until
                result.join(' ').squeeze(' ')
            end

            def to_s
                encode
            end

        end # VFormat::Value::RecurPreRFC


        class Duration < Struct.new(nil, :neg, :weeks, :days, :hours, :minutes, :seconds)
            include Mixin

            register :duration

            DURATION_REGEXP = /\A([-+])?P(\d+W)?(\d+D)?T?(\d+H)?(\d+M)?(\d+S)?\z/

            def self.new(arg)
                case arg
                when String
                    raise ArgumentError, 'invalid duration' unless
                        m = DURATION_REGEXP.match(arg)

                    super(
                        m[1] == '-' ? true : false, 
                        m[2].to_i,
                        m[3].to_i,
                        m[4].to_i,
                        m[5].to_i,
                        m[6].to_i
                    )
                else
                    super(*arg)
                end
            end

            def to_s
                s = []
                s << "#{seconds}D" unless seconds == 0
                s << "#{minutes}M" unless minutes == 0
                s << "#{hours}H"   unless hours   == 0
                s << "T"           unless s.empty?
                s << "#{days}D"    unless days    == 0
                s << "#{weeks}W"   unless weeks   == 0
                s.reverse!
                s.empty? ? "P0M" : "P#{s.join('')}"
            end
        end

    end # VFormat::Value


    #
    # Encoders
    #
    
    module Encoder
        class VCALENDAR10 < PreRFC
            version '1.0'

            def_component VFormat::VCALENDAR10
            def_component VEVENT10
            def_component VTODO10

            def_value Value::RecurPreRFC  # :recur
        end

        class ICALENDAR20 < RFC2425
            # TODO - Outlook pry nezvlada zalamovani kdekoliv, jak povoluje specifikace
            
            version '2.0'
            previous_version VCALENDAR10

            def_component VCALENDAR20
            def_component VEVENT20
            def_component VTODO20
            def_component VALARM20
            def_component VTIMEZONE20
            def_component STANDARD20
            def_component DAYLIGHT20

            def_value Value::Recur          # :recur
            def_value Value::PeriodList     # :period_list
            def_value Value::Duration       # :duration
            def_value Value::UTCOffsetICal  # :utc_offset

            register_as_default

            def self.encode_value_type(value_type)
                @value_type_to_encoded[value_type] # velkymi pismeny
            end

            def detect_encoding(raw_value)
                super
                @params['ENCODING'] = 'BASE64' if @enc_type == :b64
            end
        end
    end # VFormat::Encoder

end

# vim: shiftwidth=4 softtabstop=4 expandtab
