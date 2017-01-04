#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
require 'date'

module VFormat

    # Modul +Value+ obsahuje objekty reprezentujici hodnoty atributu.
    #
    module Value

        # Interface Value::* objektu
        #
        module Mixin
            # metody v ClassMixin budou pridany jako metody tridy pri 
            # +include Mixin+.
            #
            module ClassMixin
                # [Symbol] Nazev tohoto typu
                #
                attr_reader :type
                
                # Vytvori novy objekt dekodovanim +raw+ hodnoty (objekt
                # typu +VFormat::Value::Raw). 
                #
                # Parametr +encoder+ je trida encoderu, ktery se pouziva pro dekodovani
                # tohoto atributu. Defaultne je to +VFormat::Encoder::RFC2425+.
                #
                # Muze vyvolat vyjimku +VFormat::DecodeError+, jestlize hodnotu
                # nelze dekodovat.
                #
                def decode_raw(raw, encoder = VFormat::Encoder::RFC2425)
                    decode_wrap_error { decode(raw.to_utf8, encoder) }
                end

                # Vytvori novy objekt dekodovanim retezce +str+.
                #
                # Parametr +encoder+ je trida encoderu, ktery se pouziva pro dekodovani
                # tohoto atributu.
                #
                # Muze vyvolat vyjimku, jestlize hodnotu nelze dekodovat.
                #
                def decode(str, encoder)
                    new(str)
                end

                def decode_wrap_error
                    begin
                        yield
                    rescue 
                        raise DecodeError, $!.message, $!.backtrace
                    end
                end

                # Vytvori metody +VFormat::Attribute#<type>=+ a +VFormat::Attribute#<type>?+.
                #
                def register(type)
                    @type = type

                    unless Attribute.method_defined? "#{type}?"
                        Attribute.module_eval "def #{type}?; value_type?(:#{type}); end"
                        Attribute.module_eval "def #{type}=(v); @value = @encoder.value_type_class(:#{type}).new(v); end"
                    end

                    self
                end

                def inherited(subclass) #:nodoc:
                    subclass.instance_variable_set(:@type, @type||= nil)
                end
            end

            def self.append_features(klass)
                super
                class << klass
                    include Mixin::ClassMixin
                end
            end
            
            # Nazev typu
            #
            def type
                self.class.type
            end

            # Vraci hodnotu zakodovanou do retezce pro prime vlozeni do rfc2425 ci
            # pribuzneho formatu.
            #
            # Parametr +encoder+ je trida encoderu, ktery se pouziva pro kodovani
            # tohoto atributu. Defaultne je to +VFormat::Encoder::RFC2425+.
            #
            # Muze vyvolat vyjimku +VFormat::EncodeError+, jestlize je hodnota
            # objektu neslucitelna se zivotem.
            #
            def encode(encoder = Encoder::RFC2425)
                to_s
            end

            # Parametr +encoder+ je trida encoderu, ktery se pouziva pro dekodovani
            # tohoto atributu. Defaultne je to +VFormat::Encoder::RFC2425+.
            #

            # Zvolano z encoderu pred volanim +encode+ pro prizpusobeni
            # parametru encoderu.
            # 
            def customize_encoder(enc_instance)
                # nastavi nebo smaze VALUE parametr
                #
                if enc_instance.attribute.default_value_type == type
                    enc_instance.params.delete 'VALUE'
                else
                    enc_instance.params['VALUE'] = enc_instance.class.encode_value_type(type)
                end
            end

            # deep clone
            #
            def copy
                Marshal.load(Marshal.dump(self))
            end

        private

            def check_posint(v)
                if String === v
                    raise ArgumentError, "invalid value for positive integer: `#{v}'" unless
                        v =~ POSINT_REGEXP
                end

                v.to_i
            end

            def check_int(v)
                if String === v
                    raise ArgumentError, "invalid value for integer: `#{v}'" unless
                        v =~ INT_REGEXP
                end

                v.to_i
            end
        end


        # Objekt reprezentujici nedekodovanou hodnotu atributu. Vklada se do
        # rfc2425 beze zmeny, vcetne atributu ENCODIG, CHARSET a VALUE.
        #
        class Raw < String
            include Mixin

            register :raw

            # [nil|String] raw hodnota muze byt v libovolnem charsetu
            #
            attr_accessor :charset
            
            # [nil|Symbol] v jakem kodovani se ma hodnota zakodovat (nil -
            # autodetekce, :b64 - BASE64, :qp - QUOTED-PRINTABLE)
            #
            attr_accessor :enc_type

            def self.decode_raw(raw, encoder = VFormat::Encoder::RFC2425)
                raw.dup
            end


            def initialize(args = [])
                @enc_type = args[1]
                @charset  = args[2]
                super(args[0])
            end

            # Vrati sam sebe, nebo novy String se svoji hodnotou prekodovanou do
            # UTF-8.
            #
            def to_utf8
                # mezery na zacatku encoding hodnoty posilaji Motorola telefony
                # 
                if charset and @charset !~ /^\s*UTF-?8|ASCII|US-ASCII\s*$/i
                    self.class.to_utf8(self, @charset)
                else
                    self
                    force_encoding_vformat('UTF-8')
                end
            end

            def customize_encoder(enc_instance)
                enc_instance.enc_type = enc_type
                enc_instance.charset  = charset
                
                # Raw necha parametr VALUE beze zmeny
            end
        end


        # 8bitova data - nespecifikovany neescapovany format
        #
        class StringValue < String
            include Mixin
            register :string
        end


        class Uri < StringValue
            register :uri
        end


        class Url < Uri
            register :url
        end


        class Cid < Uri
            register :cid
        end


        class Binary < StringValue
            register :binary

            def self.decode_raw(raw, encoder = VFormat::Encoder::RFC2425)
                # neprovedeme prevod do UTF-8
                #
                new(raw) 
            end

            def customize_encoder(enc_instance)
                enc_instance.enc_type = :b64
                enc_instance.charset  = false
                super
            end
        end


        # Textova hodnota. V zakodovanem tvaru jsou zaescapovany znaky "\n",
        # ";", "," a "\".
        # 
        class Text < StringValue
            register :text

            def self.decode(str, encoder)
                new(encoder.unescape_text(str))
            end

            def encode(encoder = Encoder::RFC2425)
                encoder.escape_text(self)
            end
        end


        # Textova hodnota. V zakodovanem tvaru by nemelo byt nic zaescapovano.
        # 
        class TextPreRFC < StringValue
            register :text
        end


        # Pole textovych hodnot (obycejnych String objektu). V
        # zakodovanem tvaru jsou jednotlive hodnoty oddelene carkou.
        #
        class TextList < Array
            include Mixin

            register :text_list

            def self.decode(str, encoder)
                new(
                    (str + ',').scan(/(?:\\.|[^,\\])*(?:,|\\,\z)/m).map do |v| 
                        encoder.unescape_text(v[0..-2])
                    end
                )
            end

            alias array_initialize initialize
            
            # +arr+ muze byt pole retezcu nebo jediny retezec, ktery se stane
            # jedinym prvkem noveho seznamu
            #
            def initialize(arr)
                super(Array === arr ? arr.map {|a| a.to_s} : [arr.to_s])
            end

            def encode(encoder = Encoder::RFC2425)
                map {|v| encoder.escape_text(v)}.join(',')
            end
        end


        # Pole textovych hodnot (obycejnych String objektu). V zakodovanem tvaru
        # jsou jednotlive hodnoty oddeleny strednikem.
        # 
        class TextListPreRFC < TextList
            def self.decode(str, encoder)
                new(
                    (str + ';').scan(/(?:\\.|[^;\\])*(?:;|\\;\z)/m).map do |v| 
                        encoder.unescape_text(v[0..-2])
                    end
                )
            end

            def encode(encoder = Encoder::PreRFC)
                map {|v| encoder.escape_text(v)}.join(';')
            end
        end

        
        # Tato trida reprezentuje hodnotu delici se na casti slozene z nekolika
        # retezcu.
        #
        # Trida je potomek pole majici za prvky pole retezcu.
        #
        # V zakodovanem tvaru jsou jednotlive casti oddeleny strednikem a
        # retezce v nich oddeleny carkou.
        # 
        class Structured < Array
            include Mixin

            register :structured

            def self.decode(str, encoder)
                a = []
                last = nil

                (str + ';').scan(/(?:\\.|[^,;\\])*(?:,|;|\\;\z)/m) do |v|
                    a << (last = []) unless last
                    last << encoder.unescape_text(v[0..-2])
                    last = nil if v[-1] == ?;
                end

                new(a)
            end

            # Parametr +arr+ se automaticky zkonvertuje do pole s polema
            # retezcu.
            #
            # Priklad zkraceneho zapisu pri inicializaci hodnoty:
            #
            #   vcard.ORG = ['My company', 'Department']
            #
            # to same jako plny zapis:
            #
            #   vcard.ORG.structured = [['My company'], ['Department']]
            #
            def initialize(arr)
                super(Array === arr ? arr : [arr])
                map! {|v| Array === v ? v.dup : [v.to_s]}
            end


            def encode(encoder = Encoder::RFC2425)
                map do |a| 
                    a.map {|v| encoder.escape_text(v)}.join(',')
                end.join(';')
            end
        end


        class StructuredPreRFC < TextListPreRFC
            register :structured

            def initialize(arr)
                array_initialize(Array === arr ? arr : [arr])
                map! {|v| Array === v ? [v.first.to_s] : [v.to_s]}
            end

            def encode(encoder = Encoder::PreRFC)
                map {|v| encoder.escape_text(v.first)}.join(';')
            end
        end


        # Obecne pole objektu s +VFormat::Value::Mixin+ interfacem. V
        # zakodovanem tvaru jsou jednotlive hodnoty oddeleny carkou.
        # 
        class GenericList < Array
            include Mixin

            class << self
                # trida prvku v poli
                # 
                attr_reader :item_class

                # oddelovac pole
                # 
                attr_accessor :separator

                def register(type, item_class)
                    @separator ||= ','
                    @item_class  = item_class
                    super(type)
                end

                def decode(str, encoder)
                    new(str.split(separator, -1).map {|v| @item_class.decode(v, encoder)})
                end
            end

            def initialize(arr)
                super(Array === arr ? arr : [arr])
                klass = self.class.item_class
                map! {|v| klass === v ? v.copy : klass.new(v)}
            end

            def separator
                self.class.separator
            end

            def encode(encoder = Encoder::RFC2425)
                sep = separator
                str = map {|v| v.encode(encoder)}.join(sep)

                raise EncodeError, "items contains separator `#{sep}'" unless
                    str.count(sep) == (size == 0 ? 0 : size - 1)
                str
            end
        end


        # Stejny jako +GenericList+, ale hodnoty jsou oddeleny strednikem.
        #
        class GenericParts < GenericList
            def self.register(type, item_class)
                @separator = ';'
                super
            end
        end


        class PeriodList < GenericList
            register :period_list, StringValue
        end


        class Geo < GenericParts
            register :geo, StringValue
        end


        class GeoPreRFC < GenericList
            register :geo, StringValue
        end


        # nepouziva se
        #
        #class Boolean < String
        #    register :boolean, %w(boolean)
        #end


        class Integer
            include Mixin

            register :integer
            
            attr_accessor :value

            def initialize(val)
                raise ArgumentError, "invalid value for integer: `#{v}'" if 
                    String === val and val !~ INT_REGEXP

                @value = val.to_i
            end

            def to_i
                @value
            end

            def to_s
                @value.to_s
            end
        end
        

        class Date < ::Date
            include Mixin

            register :date

            def self.new(arg)
                case arg
                when String
                    raise ArgumentError, "invalid date representation #{arg.inspect}" unless
                        m = DATE_REGEXP.match(arg)
                    super(m[1].to_i,  m[2].to_i, m[3].to_i)
                when ::Date, DateTime, Time
                    super(arg.year, arg.month, arg.day)
                else
                    super(*arg)
                end
            end

            def to_s
                "%04d%02d%02d" % to_a
            end

            def to_a
                [year, month, day]
            end
        end


        class DateList < GenericList
            register :date_list, Date
        end


        class DateListPreRFC < GenericParts
            register :date_list, Date
        end


        class DateTime < Struct.new(nil, :year, :month, :day, :hour, :min, :sec, :zone)
            include Mixin

            register :date_time

            def self.new(arg)
                case arg
                when String
                    if m = DATE_TIME_REGEXP.match(arg)
                        super(m[1].to_i,  m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i, m[6].to_f, m[7])

                    elsif m = DATE_REGEXP.match(arg)
                        # telefony Motorola posilaji DTSTART a DTEND u
                        # celodennich udalosti v DATE formatu i ve vCalendari
                        # 1.0, kde to neni dovoleno - prevedeme na DateTime
                        #
                        super(m[1].to_i, m[2].to_i, m[3].to_i, 0, 0, 0.0)
                    else
                        raise ArgumentError, "invalid date-time representation #{arg.inspect}"
                    end
                when Time
                    super(
                        arg.year, 
                        arg.month, 
                        arg.day, 
                        arg.hour, 
                        arg.min, 
                        arg.sec, # vsechny formaty to nepodporuji: + (arg.usec / 1_000_000.to_f),
                        t.utc? ? 'Z' : nil
                    )
                when Date
                    super(arg.year, arg.month, arg.day, 0, 0, 0.0)
                else
                    super(*arg)
                end
            end

            def to_s
                "%04d%02d%02dT%02d%02d%02g%s" % to_a # TODO - vypnout localy
            end

            # Vrati true jestlize jsou hour, min a sec rovny nule, jinak false.
            #
            def zero_time?
                hour == 0  and min == 0 and sec == 0.0
            end

            # Vrati +Time+ objekt v UTC time zone je-li +zone+ nastaveno na 'Z',
            # jinak v lokalni time zone.
            # 
            def to_time
                a = to_a
                a.pop == 'Z' ? Time.utc(*a) : Time.local(*a)
            end

            def wday
                WEEKDAYS[(d = to_time.wday) == 0 ? 6 : d - 1] rescue nil
            end
        end


        class DateTimeList < GenericList
            register :date_time_list, DateTime
        end
        

        class DateTimeListPreRFC < GenericParts
            register :date_time_list, DateTime
        end


        class UTCOffset < Integer
            register :utc_offset

            UTC_OFFSET_REGEXP = /\A([-+]?)(\d\d)(?::?(\d\d))?(?::?(\d\d))?\z/o

            def initialize(arg)
                case arg
                when String
                    raise ArgumentError, "invalid utc-offset representation #{arg.inspect}" unless
                        m = UTC_OFFSET_REGEXP.match(arg)

                    @value = m[2].to_i * 3600 + m[3].to_i * 60 + m[4].to_i
                    @value = -@value if m[1] == '-'
                else
                    @value = arg.to_i
                end
            end

            def hour
                (@value / 3600).abs
            end

            def min
                (@value % 3600) / 60
            end

            def sec
                @value % 60
            end

            def sign
                @value < 0 ? :"-" : :"+"
            end

            def to_a
                [
                    sign,
                    hour,
                    min,
                    sec,
                ]
            end

            def to_s
                if sec == 0
                    "%s%02d:%02d" % [sign, hour, min]
                else
                    "%s%02d:%02d:%02d" % to_a
                end
            end
        end


        class UTCOffsetICal < UTCOffset
            def to_s
                if sec == 0
                    "%s%02d%02d" % [sign, hour, min]
                else
                    "%s%02d%02d%02d" % to_a
                end
            end
        end


    end # VFormat::Value

end # VFormat


# vim: shiftwidth=4 softtabstop=4 expandtab
