#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#

module VFormat
    # Kazda trida v modulu Encoder odpovida nejake verzi nektereho z
    # podporovanych formatu. 
    #
    # Ve tride encoderu jsou zaregistrovany komponenty implementujici konkretni
    # verzi formatu a take tridy implementujici konkretni typy hodnot atributu.
    #
    # Instance encoderu se pouziva pro zakodovani atributu do jednotlivych
    # formatu.
    #
    module Encoder
        # Ohodnoti retezec +value+ podle toho, jakym zpusobem se muze zakodovat
        # jako hodnota parametru v atributu:
        # 
        #  :invalid    - nelze zakodovat jako hodnotu parametru
        #  :normal     - jednoduse zakodovatelna hodnota
        #  :special    - hodnota se musi zakodovat s uvozovkama okolo
        #  
        # TODO - Specialita u vCalendare:
        #  "A Semi-colon in a property parameter value must be escaped with a
        #   Backslash character (ASCII 92)"
        #
        def self.pvalue_type(value)
            if value =~ /\A(?:([^"\x00-\x1f\x7f;:,]*)|([^"\x00-\x1f\x7f]*))\z/
                $1 ? :normal : :special
            else
                :invalid
            end
        end

        # zakoduje +text+ pomoci QP kodovani
        #
        def self.encode_qp(text)
            text = [text].pack('M')
            text.gsub!(/=\n/, '')
            text.gsub!(/\n/, '=0A')
            text
        end


        class RFC2425
            ESCAPE_TEXT = {
                "\\"   => "\\\\",
                "\n"   => "\\n",
                "\r\n" => "\\n",
                ";"    => "\\;",
                ","    => "\\,",
            }
            ESCAPE_TEXT_REGEXP = Regexp.union(*ESCAPE_TEXT.keys)
            
            # Spec: ("\\" / "\;" / "\," / "\n" / "\N")
            # Note: we also accept \" for iCal.app, \t for kOrganizer and \r for
            # safety.
            #
            UNESCAPE_TEXT = {
                '\\' => "\\",
                ';'  => ";",
                ','  => ",",
                'n'  => "\n",
                'N'  => "\n",
                't'  => "\t",
                'r'  => "\r",
                '"'  => "\"",
            }
            UNESCAPE_TEXT_REGEXP = /\\([#{Regexp.escape(UNESCAPE_TEXT.keys.join(''))}])/o


            # inicializace atributu v tride
            # 
            @version                     = '1.0'
            @previous_version            = nil
            @value_type_to_class         = {}
            @encoded_to_value_type       = {}
            @value_type_to_encoded       = {}
            @components                  = {}

            class << self
                # [Hash of Classes] Mapovani mezi nazvama typu a konkretnima tridama, ktere
                # je implementuji:
                #   { :text => VFormat::Value::Text, ... }
                #
                attr_reader :value_type_to_class

                # [Hash of Arrays] Mapovani mezi zakodovanyma nazvama typu a nasima
                # nazvama typu ve +value_type_to_class+.
                # 
                attr_reader :encoded_to_value_type

                # [Hash of Strings] Mapovani mezi nazvama typu a
                # zakodovanym nazvem typu.
                # 
                attr_reader :value_type_to_encoded

                # [Hash] Mapovani mezi nazvem komponenty a tridou, ktera ji
                # implementuje.
                # 
                attr_reader :components

                # [String]
                #
                def version(v = nil)
                    v ? (@version = v) : @version
                end

                # [nil|VFormat::Encoder class]
                #
                def previous_version(v = false)
                    v == false ? @previous_version : (@previous_version = v)
                end

                # Vrati tridu s interfacem +VFormat::Value::Mixin+, ktera
                # implementuje zadany typ hodnoty atributu.
                #
                # Vyvola vyjimku, jestlize neni pozadovany typ u tohoto encoderu
                # definovan.
                #
                def value_type_class(value_type)
                    @value_type_to_class.fetch(value_type) do 
                        raise TypeError, "unknown value type :#{value_type}"
                    end
                end

                def def_value(value, *encoded_names)
                    # redefinice?
                    #
                    undef_value(value.type) if @value_type_to_class[value.type]
                        
                    encoded_names << value.type.to_s.upcase.tr('_', '-') if
                        encoded_names.empty?
                    
                    @value_type_to_class[value.type] = value
                    @value_type_to_encoded[value.type] = encoded_names.first

                    encoded_names.each {|e| (@encoded_to_value_type[e] ||= []) << value.type}

                    self
                end

                def undef_value(value_type)
                    @value_type_to_class.delete(value_type)
                    @value_type_to_encoded.delete(value_type)
                    @encoded_to_value_type.each_value {|v| v.delete(value_type)}
                    self
                end

                def def_component(c, name = nil)
                    @components[name || c.default_name] = c
                    c.default_encoder(self) if c.default_encoder == RFC2425
                    self
                end

                # Zaregistruje encoder pro vyhledani jeho komponent pomoci
                # +VFormat::[]+
                #
                def register_as_default
                    @components.keys.each {|n| VFormat::encoders[n] = self}
                end

                # Najde tridu komponenty pro zadany nazev a verzi. Vraci nil, jestlize se
                # ji nalezt nepodarilo. Neni-li zadana verze, vrati komponentu
                # pridanou do tohoto encoderu.
                #
                def component(name, version = nil)
                    if version
                        c = self

                        while c.version != version
                            return nil unless c = c.previous_version
                        end
                        
                        c.components[name]
                    else
                        @components[name]
                    end
                end

                # Spoji nekolik radku v +array+ do jedineho retezce.
                # U kazdeho encoderu muze byt spojeno jinak - zalezi na tom, jestli
                # je mezera (tabulator) na zacatku radku soucasti dat.
                #
                def unfold(array)
                    array.inject(nil) {|str, line| str ? (str << line[1..-1]) : line.dup}
                end
                
                # Escape text value.
                #
                def escape_text(text)
                    text.gsub(ESCAPE_TEXT_REGEXP) { ESCAPE_TEXT[$&] }
                end
                
                # Unescape text value.
                #
                def unescape_text(text)
                    text.gsub(UNESCAPE_TEXT_REGEXP) { UNESCAPE_TEXT[$1] }
                end

                # [nil | String] Vrati zakodovany nazev typu hodnoty atributu.
                #
                def encode_value_type(value_type)
                    (e = @value_type_to_encoded[value_type]) ? e.downcase : nil
                end

                # [nil | String] defaultni charset textu; vraci nil, coz znamena UTF-8
                #
                def default_charset
                    nil
                end

                def inherited(subclass) #:nodoc:
                    subclass.instance_variable_set(:@version, @version)
                    subclass.instance_variable_set(:@previous_version, @previous_version)
                    subclass.instance_variable_set(:@value_type_to_class, @value_type_to_class.dup)
                    subclass.instance_variable_set(:@encoded_to_value_type, Marshal.load(Marshal.dump(@encoded_to_value_type)))
                    subclass.instance_variable_set(:@value_type_to_encoded, @value_type_to_encoded.dup)
                    subclass.instance_variable_set(:@components, @components.dup)
                end

                # Prevede neco takovehodle (viz. +VFormat::parse+) na komponentu
                # a pripadne zanorene komponenty, ktera jsou zaregistrovane v tomto
                # encoderu:
                #
                # {
                #    :name       => 'VCARD',
                #    :version    => '2.1',
                #    :attributes => [
                #        ['N:...'],
                #        ['ADR:..', '...'], # byl zapsan na vice radcich
                #        ...
                #    ]
                # }
                #
                def decode_parsed(parsed_data, version = nil)
                    version ||= parsed_data[:version] || @version

                    unless comp = @components[parsed_data[:name]]
                        comp = parsed_data[:version] ? VersionedComponent : Component 
                    end

                    comp_inst = comp.allocate.init(parsed_data[:name], version, self)

                    parsed_data[:attributes].each do |atr_arr|
                        if Hash === atr_arr
                            # komponenta
                            #
                            comp_inst << decode_parsed(atr_arr, version)
                        else
                            # atribut
                            #
                            begin
                                atr = Attribute.decode(unfold(atr_arr), self)
                                atr.default_value_type = comp_inst.attribute_default_value_type(atr.name) || :text
                                comp_inst << atr
                            rescue DecodeError
                                comp_inst.invalid_lines << atr_arr
                            end
                        end
                    end

                    comp_inst
                end
            end


            def_value Value::Raw                       # :raw
            def_value Value::Text                      # :text
            def_value Value::TextList                  # :text_list
            def_value Value::Structured                # :structured
            def_value Value::Binary                    # :binary
            def_value Value::Uri                       # :uri
            def_value Value::Url                       # :url
            def_value Value::StringValue               # :string
            def_value Value::Date                      # :date
            def_value Value::DateList,     'DATE'      # :date_list
            def_value Value::DateTime                  # :date_time
            def_value Value::DateTimeList, 'DATE-TIME' # :date_time_list
            def_value Value::Integer                   # :integer
            def_value Value::Geo                       # :geo
            def_value Value::UTCOffset                 # :utc_offset


            # [VFormat::Attribute] prave kodovany atribut pomoci +encode+
            #
            attr_reader :attribute

            # [Hash] nastaveno na +attribute.params.dup+ - urceno pro upravu
            # parametru prave kodovaneho atributu. Hodnota parametru muze byt
            # nil, retezec a pole retezcu.
            #
            attr_reader :params
            
            # [nil|Symbol] jake kodovani se pouzije pro hodnotu prave
            # kodovaneho atributu:
            #   nil - autodetekce
            #   :b64, :qp - pouzit zadane kodovani
            #
            attr_accessor :enc_type
            
            # [nil|false|String] jaky charset se nastavi do CHARSET parametru
            # (jestlize to format dovoluje):
            #   nil    - autodetekce
            #   false  - zadny CHARSET nepridavat
            #   String - pridat CHARSET s touto hodnotou
            #
            attr_accessor :charset

            # vrati atribut +atr+ zakodovany do retezce
            #
            def encode(atr)
                @attribute = atr
                @params    = atr.params.dup
                @enc_type  = nil
                @charset   = nil
                @result    = result = ''

                result << atr.group << '.' if atr.group
                result << atr.name

                @attribute.value.customize_encoder(self)
                raw_value = @attribute.value.encode(self.class)
                
                detect_encoding(raw_value)

                @params.keys.sort.each do |pname|
                    pvalues = Array(@params[pname])
                    encode_param(pname, pvalues) unless pvalues.empty?
                end

                result << ':'
                append_raw_value(raw_value)
                result
            end

        private

            def detect_encoding(raw_value)
                unless @enc_type # nastavit ho mohla +value.encode+ metoda
                    # musime provest detekci kodovani - pouzijeme b64 i v
                    # pripade, ze raw_value obsahuje \r a \n znaky
                    #
                    @enc_type = :b64 if raw_value.enc_is_b64?
                end

                if @enc_type == :b64
                    @params['ENCODING'] = 'b'
                else
                    @params.delete 'ENCODING'
                end

                @params.delete 'CHARSET'
            end

            def encode_param(pname, pvalues)
                @result << ';' << pname << '=' << pvalues.map do |v|
                    case Encoder.pvalue_type(v)
                    when :normal
                        v
                    when :special
                        "\"#{v}\""
                    else
                        raise EncodeError, "Invalid parameter value: #{v.inspect}"
                    end
                end.join(',')
            end

            def append_raw_value(raw_value)
                # rfc 2426 (vCard), 2.6 Line Delimiting and Folding:
                # After generating a content line,
                # lines longer than 75 characters SHOULD be folded according to the
                # folding procedure described in [MIME-DIR].
                #
                # rfc 2445 (iCalendar), 4.1 Content Lines:
                # Lines of text SHOULD NOT be longer than 75 octets, excluding the line
                # break. Long content lines SHOULD be split into a multiple line
                # representations using a line "folding" technique. That is, a long
                # line can be split between any two characters by inserting a CRLF
                # immediately followed by a single linear white space character (i.e.,
                # SPACE, US-ASCII decimal 32 or HTAB, US-ASCII decimal 9). Any sequence
                # of CRLF followed immediately by a single linear white space character
                #  is ignored (i.e., removed) when processing the content type.
                #
                # Note:
                # Line folding is described in terms of characters not bytes.
                # In particular, it would be an error to put a line break within
                # a UTF-8 character.
                #
                if @enc_type == :b64
                    # zafoldujeme vse pred b64 daty, tesne pred nimi zalomime a zbytek
                    # nechame na b64 kodovani samotnem
                    #
                    @result.gsub!(/.{75,75}(?=.)/u) {|s| "#{s}#{CRLF} "} if
                        @result.size > 75
                    @result << CRLF << ' ' << [raw_value].pack('m').gsub("\n", CRLF + ' ')
                    @result.chop!
                else
                    # folding se nesmi provest na uplnem konci retezce - /(?=re)/ je
                    # zero-width positive lookahead
                    #
                    @result << raw_value
                    @result.gsub!(/.{75,75}(?=.)/u) {|s| "#{s}#{CRLF} "} if
                        @result.size > 75 # 30% zrychleni kodovani celeho atributu
                    @result << CRLF
                end
            end
        end


        class PreRFC < RFC2425
            def_value Value::TextPreRFC                       # :text
            def_value Value::TextListPreRFC                   # :text_list
            def_value Value::StructuredPreRFC                 # :structured
            def_value Value::DateTimeListPreRFC, 'DATE-TIME'  # :date_time_list
            def_value Value::DateListPreRFC,     'DATE'       # :date_list
            def_value Value::Cid, 'CONTENT-ID', 'CID'         # :cid
            def_value Value::GeoPreRFC                        # :geo


            ESCAPE_TEXT = {
                "\\" => "\\\\",
                ";"  => "\\;",
            }
            ESCAPE_TEXT_REGEXP = Regexp.union(*ESCAPE_TEXT.keys)
            
            UNESCAPE_TEXT = {
                '\\' => "\\",
                ';'  => ";",
            }
            UNESCAPE_TEXT_REGEXP = /\\([#{Regexp.escape(UNESCAPE_TEXT.keys.join(''))}])/o

            # Escape text value as described in vCard 2.1 spec.
            #
            def self.escape_text(text)
                text.gsub(ESCAPE_TEXT_REGEXP) { ESCAPE_TEXT[$&] }
            end
            
            # Unescape text value as described in vCard 2.1 spec.
            #
            def self.unescape_text(text)
                text.gsub(UNESCAPE_TEXT_REGEXP) { UNESCAPE_TEXT[$1] }
            end

            def self.unfold(array)
                array.join('')
            end

            def self.encode_value_type(value_type)
                @value_type_to_encoded[value_type] # velkymi pismeny
            end

            # [nil | String] defaultni charset textu; melo by vracet "ASCII",
            # ale vraci "ISO-8859-1", coz je potreba napriklad kvuli telefonum
            # Motorola
            #
            def self.default_charset
                'ISO-8859-1'
            end

            def encode_param(pname, pvalues)
                if pname == 'TYPE'
                    # prefix "TYPE=" se ve vCard 2.1 vynechava
                    #
                    @result << ';' << pvalues.join(';')
                else
                    super
                end
            end
            
            def detect_encoding(raw_value)
                unless @enc_type # nastavit ho mohla +value.customize_encoder+ metoda
                    # musime provest detekci kodovani
                    #
                    if raw_value.raw_is_b64?
                        @enc_type = :b64
                    elsif @result.size + raw_value.size >= 75 or raw_value.raw_is_qp?
                        # :qp pouzijeme kdykoliv je potreba provest folding, nebo
                        # escapovat spec. znaky, jako jsou napr. \r, \n
                        #
                        @enc_type = :qp
                    end
                end

                case @enc_type
                when :b64 
                    @params['ENCODING'] = 'BASE64'
                when :qp
                    @params['ENCODING'] = 'QUOTED-PRINTABLE'
                else
                    @params.delete 'ENCODING'
                end
                
                case @charset
                when nil
                    # autodetekce charsetu - je potreba pouze v pripade, ze
                    # raw_value obsahuje divne znaky - tzn. je nastaven
                    # @enc_type
                    # 
                    if @enc_type
                        @params["CHARSET"] = 'UTF-8'
                    else
                        @params.delete "CHARSET"
                    end
                when false
                    @params.delete "CHARSET"
                else
                    @params["CHARSET"] = @charset
                end
            end

            def append_raw_value(raw_value)
                # rfc 2425 [MIME-DIR], 5.8.1:
                # A logical line MAY be continued on the next physical line anywhere
                # between two characters by inserting a CRLF immediately followed by a
                # single <WS> (white space) character.
                #
                case @enc_type
                when :b64 
                    # tesne pred b64 daty zalomime a zalamani data nechame na
                    # b64 kodovani samotnem; na konec dat nechame dat prazdny
                    # radek navic
                    #
                    @result << CRLF << ' ' << [raw_value].pack('m').gsub("\n", CRLF + ' ')
                    @result.chop!

                when :qp
                    # rfc 2045, 6.7, chapter 5:
                    # The quoted-printable specs says that softbreaks should be generated by inserting a =\r\n
                    # without follwing <WS>
                    #
                    raw_value = Encoder.encode_qp(raw_value)

                    # neni potreba resit delku retezce v UTF-8 - qp koduje do ASCII
                    #
                    if @result.size + raw_value.size <= 75
                        # neni potreba delat folding
                        #
                        @result << raw_value
                    else 
                        # folding se nesmi provest pred startem qp dat, uvnitr
                        # quotovaci sequence a na uplnem konci retezce
                        #
                        if @result.size < 70
                            @result << raw_value
                            @result.gsub!(/.{70,72}[^=][^=](?=.)/u) {|s| "#{s}=#{CRLF}"} 
                        else
                            raw_value.gsub!(/.{70,72}[^=][^=](?=.)/u) {|s| "#{s}=#{CRLF}"} if
                                raw_value.size > 75

                            @result << '=' << CRLF # zalomime jeste pred vlastnimi qp daty
                            @result << raw_value
                        end
                    end

                else
                    # nemusime provadet folding - vsechny dlouhe radky maji :qp
                    # enc_type
                    #
                    @result << raw_value
                end

                @result << CRLF
            end


            # Mixin encoderu pro podporu vadnych klientu, kteri se nevyrovnaji s foldingem.
            # Priklad pouziti:
            #
            #   class VCARD21Fix < VFormat::Encoder::VCARD21
            #       include VFormat::Encoder::PreRFC::WithoutFolding
            #   end
            #
            module WithoutFolding
                def append_raw_value(raw_value)
                    if @enc_type == :qp
                        @result << Encoder.encode_qp(raw_value) << CRLF
                    else
                        super
                    end
                end
            end
            

            # Mixin pro encoder pro podporu vadnych klientu, kteri pridavaji
            # mezeru navic na zacatek foldovanych radku (napr. Nokia 6300).
            # Priklad pouziti:
            #
            #   class VCALENDAR10Fix < VFormat::Encoder::VCALENDAR10
            #       include VFormat::Encoder::PreRFC::FoldingWithIndent
            #   end
            #
            module FoldingWithIndent
                module ClassMixin
                    def unfold(array)
                        array.inject(nil) {|str, line| str ? (str << line.sub(/\A[ \t]/, '')) : line.dup}
                    end
                end

                def self.append_features(klass)
                    super
                    class << klass
                        include FoldingWithIndent::ClassMixin
                    end
                end
            end
            

            # Mixin pro encoder pro podporu nekorektnich klientu, kteri v
            # textovych hodnotach escapuji znaky ";" a "\" (napr. Nokia 6300).
            # Priklad pouziti:
            #
            #   class VCALENDAR10Fix < VFormat::Encoder::VCALENDAR10
            #       include VFormat::Encoder::PreRFC::TextEscaped
            #   end
            #
            module TextEscaped
                def self.append_features(klass)
                    super
                    klass.def_value Value::Text # :text
                end
            end
        end

    end # VFormat::Encoder
end # VFormat



