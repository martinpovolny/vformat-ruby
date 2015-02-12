#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#

module VFormat
    class Component
        # inicializace atributu v tride
        # 
        @attributes           = {}
        @multi_attributes     = {}
        @attribute_converters = {}
        @default_name     = 'UNKNOWN'
        @default_encoder  = Encoder::RFC2425

        class << self # metody tridy

            # [String]
            #
            def default_name(v = nil)
                v ? (@default_name = v) : @default_name
            end

            # [VFormat::Encoder class]
            #
            def default_encoder(v = nil)
                v ? (@default_encoder = v) : @default_encoder
            end

            # [Hash] definice vsech atributu
            #
            attr_reader :attributes

            # [Hash] jmena atributu, ktere mohou mit vice hodnot
            #
            attr_reader :multi_attributes

            # [Hash] Proc objekty pro konverzi atributu mezi verzemi
            #
            attr_reader :attribute_converters

            def def_attribute(name, types, args = nil)
                @attributes[name] = Array(types).freeze

                if args
                    @multi_attributes[name]     = true if args[:multiple]
                    @attribute_converters[name] = args[:converter] if args[:converter]
                end

                self
            end

            def undef_attribute(name)
                @attributes.delete(name)
                @multi_attributes.delete(name)
                @attribute_converters.delete(name)
                self
            end

            # [Symbol] vrati/nastavi jmeno metody, ktera dokaze zkonvertovat predany atribut z
            # jine verze componenty do verze teto komponenty, nebo nil
            # 
            def attribute_converter(atr, v = false)
                v == false ? @attribute_converters[atr.name] : @attribute_converters[atr.name] = v
            end

            def inherited(subclass) #:nodoc:
                subclass.instance_variable_set(:@attributes, @attributes.dup)
                subclass.instance_variable_set(:@multi_attributes, @multi_attributes.dup)
                subclass.instance_variable_set(:@default_name, @default_name)
                subclass.instance_variable_set(:@default_encoder, @default_encoder)
                subclass.instance_variable_set(:@attribute_converters, @attribute_converters.dup)
            end

        end

        def_attribute 'NAME',    :text
        def_attribute 'PROFILE', :text
        def_attribute 'SOURCE',  :uri

        
        # [String] nazev komponenty velkymi pismeny, napr. 'VCARD', 'VEVENT', 'VTODO', ...
        #
        attr_accessor :name
        
        # [String] verze komponenty, napr. "1.0", "2.0", "2.1", "3.0", ...
        #
        attr_accessor :version
        
        # [Array of VFormat::Attribute or VFormat::Component]
        #
        attr_accessor :attributes 

        # [VFormat::Encoder class] jaka trida encoderu se ma pouzit pro kodovani
        # teto komponenty
        #
        attr_accessor :encoder
        

        # Vrati novou komponentu.
        # Jestlize neni +name+ zadano, pouzije se +default_name+.
        # Jestlize neni +version+ zadano, pouzije se +default_version+.
        # Jestlize neni +encoder+ zadano, pouzije se +default_encoder+.
        #
        def initialize(name = nil, version = nil, encoder = nil)
            init(name, version, encoder)
            init_attributes
            yield(self) if block_given?
        end

        def init(name = nil, version = nil, encoder = nil) #:nodoc:
            @name               = name || default_name
            @encoder            = encoder || default_encoder
            @version            = version || default_version
            @attributes         = []
            @invalid_lines      = nil
            @invalid_attributes = nil
            self
        end
            
        def init_attributes
        end

        # deep clone
        #
        def copy
            Marshal.load(Marshal.dump(self))
        end

        def default_name
            self.class.default_name
        end

        def default_encoder
            self.class.default_encoder
        end

        # Zkratka pro +encoder.version+.
        #
        def default_version
            @encoder.version
        end

        # [Array of String] chybne radky zjistene pri parsovani pomoci
        # +VFormat::decode_raw+
        #
        def invalid_lines
            @invalid_lines ||= []
        end

        def invalid_lines?
            @invalid_lines and !@invalid_lines.empty?
        end
        
        # [Array of String] attributy s chybnou hodnotou odebrane z +attributes+
        # pri volani +VFormat::Component#normalize_attributes+
        #
        def invalid_attributes 
            @invalid_attributes ||= []
        end

        def invalid_attributes?
            @invalid_attributes and !@invalid_attributes.empty?
        end

        # komponenta ma +group+ vzdy nil
        #
        def group
            nil
        end

        def ==(other)
            Component  === other and 
            @name       == other.name and 
            @attributes == other.attributes
        end

        # call-seq:
        # component.first(name)        #=> VFormat::Attribute or VFormat:Component or nil
        # component.first(name, group) #=> VFormat::Attribute or VFormat:Component or nil
        #
        # Jestlize neni zadany +group+, potom najde v +attributes+ prvni
        # atribut (komponentu), jehoz nazev je +name+, jinak atribut se shodnym
        # +group+ i +name+. +group+ muze byt nil, coz znaci prvni atribut
        # majici +group+ nil a nazev +name+.
        #
        # Vrati nil, jestlize zadny takovy attribut neexistuje.
        #
        def first(name, group = false)
            if group == false
                @attributes.find {|a| a.name == name}
            else
                @attributes.find {|a| a.name == name and a.group == group}
            end
        end

        # call-seq:
        # component[name]        #=> VFormat::Attribute or VFormat:Component
        # component[name, group] #=> VFormat::Attribute or VFormat:Component
        #
        # To same jako +first+, ale nikdy nevraci +nil+. Jestlize hledany
        # atribut (komponenta) neexistuje, potom misto nil vrati
        # +VFormat::NilAttribute+.
        #
        # Priklad:
        #
        #   vcard['NAME']        #=> VFormat::Attribute
        #   vcard['NAME'].value  #=> String
        #   vcard['TEST'].value? #=> true
        #   vcard['TEST']        #=> VFormat::NIL_ATTRIBUTE
        #   vcard['TEST'].value  #=> nil
        #   vcard['TEST'].value? #=> false
        #   vcard['TEST'].params #=> {}
        #
        def [](name, group = false)
            first(name, group) || NIL_ATTRIBUTE
        end

        # call-seq:
        # component[name] = value #=> value
        #
        # To same jako +component.replace(name, value)+, ale vraci +value+.
        # Priklady:
        #   
        #   vcard['TEL'] = '1234' #=> '1234'
        #   vcard['CATEGORIES'] = ['BIRTHDAY', 'PRIVATE']
        #
        def []=(name, value)
            replace(name, value)
            value
        end

        def attribute?(name, group = false)
            Attribute === first(name, group)
        end

        alias attr? attribute?

        def component?(name)
            Component === @attributes.find {|a| a.name == name}
        end

        alias comp? component?
        
        # call-seq:
        # component.delete(name)  #=> Array of Attributes
        # component.delete(name, group) #=> Array of Attributes
        #
        # Smaze vsechny attributy (komponenty) se zadanym nazvem (a skupinou) z
        # +attributes+ a vrati je v poli. Argumenty:
        #
        #   +name+      - [String] jmeno atributu velkymi pismeny
        #   +group+     - [nil|String] jmeno skupiny atributu velkymi pismeny
        #
        # Jestlize neni zadany +group+, potom smaze vsechny atributy, jejichz
        # nazev je +name+.  Jinak smaze vsechny se shodnym +group+ i +name+.
        # Argument +group+ nastaveny na nil znaci pouze atributy s +group+
        # nastavenym na nil.
        # 
        # Priklady:
        #
        #  vcard.delete 'TEL' #=> [...]
        # 
        def delete(name, group = false)
            if group == false
                deleted, @attributes = @attributes.partition {|a| a.name == name}
            else
                deleted, @attributes = @attributes.partition {|a| a.name == name and a.group == group}
            end

            deleted
        end

        # Prida +attribute+ na konec +attributes+. +attribute+ muze byt
        # VFormat::Attribute nebo VFormat::Component.
        #
        def <<(attribute)
            @attributes << attribute
        end

        def new_attribute(name, a1 = nil, a2 = nil, &block) #:nodoc:
            if c = @encoder.components[name]
                c.new(name, @version, @encoder, &block)
            elsif default_value_type = attribute_default_value_type(name) or name =~ /^X-/
                a2 ||= {}
                a2[:encoder] ||= @encoder
                a2[:default_value_type] ||= (default_value_type || :text)

                Attribute.new(name, a1, a2, &block)
            else
                raise ArgumentError, "unsupported attribute `#{name}'"
            end
        end
            
        # call-seq:
        # component.add(attribute) #=> VFormat::Attribute
        # component.add(component) #=> VFormat::Component
        # component.add(name, ...) #=> VFormat::Attribute|VFormat::Component
        # component.add(name, ...) { ... } #=> VFormat::Attribute|VFormat::Component
        #
        # Varianta s parametrem +attribute+ nebo +component+ pridaji parametr na
        # konec +attributes+ a vrati ho.
        # 
        # Jinak jestlize je +name+ zaregistrovan jako znama komponenta v
        # encoderu (+encoder+), potom se na ni zavola +new+.
        #
        # Jestlize je +name+ zaregistrovan jako znamy atribut v komponente,
        # zavola se +VFormat::Attribute.new+ s predanymi argumenty a nastavenym
        # encoderem a defaultnim typem hodnoty.
        #
        # Jinak se vyvola vyjimka.
        #
        # Nove vytvoreny objekt se prida na konec +attributes+ a pote se vrati.
        #
        # Parametr +name+ musi byt velkymi pismeny.
        #
        #   vcard.add 'TEL', '1234', 'TYPE' => 'WORK' #=> new_attr
        #   vcard.add 'NICKNAME', ['jean', 'jan'] #=> new_attr
        #   vcard.add 'X-SOMETHING', 123, :value_type => :integer #=> new_attr
        #   vcal.add('VEVENT') {|event| ... } #=> event
        #
        def add(name, a1 = nil, a2 = nil, &block)
            case name
            when Component, Attribute
                atr = name
            else
                atr = new_attribute(name, a1, a2, &block)
            end

            @attributes << atr
            atr
        end

        # Smaze attributy (komponenty) s nazvem +name+ a prida novy atribut
        # (komponentu) na pozici prvniho smazane atributu. Viz. +delete+ a +add+
        # metody.
        #
        # Priklad:
        #
        #  vcard.replace 'TEL', '123', 'TYPE' => 'WORK'  #=> new_attr
        #
        def replace(name, a1 = nil, a2 = nil, &block)
            new_attr = nil

            @attributes.map! do |a| 
                if a.name == name
                    if new_attr
                        nil
                    else
                        new_attr = new_attribute(name, a1, a2, &block)
                    end
                else
                    a
                end
            end
            @attributes.compact!

            new_attr ? new_attr : add(name, a1, a2, &block)
        end

        # call-seq:
        # component.each { ... }       #=> component
        # component.each(name) { ... } #=> component
        # component.each(name, group) { ... } #=> component
        # component.each               #=> Enumerable::Enumerator
        # component.each(name)         #=> Enumerable::Enumerator
        # component.each(name, group)  #=> Enumerable::Enumerator
        #
        # Varianta s blokem: jestlize neni zadany +name+, potom je volani shodne s
        # +component.attributes.each {...}+, jinak jestlize neni zadany +group+,
        # potom zavola blok pro kazdy atribut z +attributes+, jehoz nazev je
        # +name+, jinak pro kazdy atribut se shodnym +group+ i +name+. +group+
        # muze byt nil, coz znaci vsechny atributy majici +group+ nil a nazev
        # +name+.
        #
        # Bez bloku: vrati +Enumerable::Enumerator+, ktery iteruje pres vsechny
        # atributy v +attributes+ splnujicich stejnou podminku jako "varianta s
        # blokem".
        #
        # Priklad ziskani vsech telefonnich cisel z VCARDu:
        #   vcard.each('TEL').to_a #=> Array of VFormat::Attributes
        #   
        # Dalsi priklady:
        #   comp.each('VEVENT') {|e| ... } #=> comp
        #   comp.each('RRULE').map {|r| ... } #=> Array
        #
        def each(name = nil, group = false, &block)
            if block
                if name
                    if group == false
                        @attributes.each {|a| yield(a) if a.name == name}
                    else
                        @attributes.each {|a| yield(a) if a.name == name and a.group == group}
                    end
                else
                    @attributes.each(&block)
                end

                self
            else
                enum_for(:each, name, group)
            end
        end

        # call-seq:
        # component.each_attribute(recur=true) {|attr, comp| ... } #=> component
        #
        # Zavola blok pro kazdy atribut v +component+. Jestlize je +recur+ true,
        # potom prochazi take vsechny zanorene komponenty. Parametr +comp+ v
        # bloku je komponenta, ve ktere se atribut nachazi. 
        #
        # Jestlize blok vrati :back, potom se prestane prochazet rozpracovana
        # komponenta a vrati se zpet k nadrazene.
        #
        def each_attribute(recur = true)
            recur_proc = proc do |comp|
                comp.attributes.each do |atr|
                    if Attribute === atr
                        break if yield(atr, comp) == :back
                    else
                        recur_proc.call(atr) if recur
                    end
                end
            end

            recur_proc.call(self)
        end

        # call-seq:
        # component.each_component(recur=true, this=false) {|comp| ... } #=> component
        #
        # Zavola blok pro kazdou komponentu v +component+. Jestlize je +recur+
        # true, potom prochazi take vsechny zanorene komponenty. Jestlize je
        # +this+ true, potom na zacatku zavola blok take s +component+.
        #
        # Jestlize blok vrati :back, potom se prestane prochazet rozpracovana
        # komponenta a vrati se zpet k nadrazene.
        #
        def each_component(recur = true, this = false)
            recur_proc = proc do |comp|
                comp.attributes.each do |atr|
                    unless Attribute === atr
                        break if yield(atr) == :back
                        recur_proc.call(atr) if recur
                    end
                end
            end

            yield(self) if this
            recur_proc.call(self)
        end

        # Vytvori a vrati novou komponentu konverzi teto komponenty do
        # +new_ver+. Dale pomoci +to_version+ prevede vsechny zanorene
        # komponenty.
        #
        #   +new_ver+ - [nil | String] jestlize neni zadana, pouzije se 
        #               +new_enc.version+.
        #   +new_enc+ - [nil | VFormat::Encoder::*] jestlize neni zadan, pouzije se 
        #               pro jeho nalezeni +VFormat::encoder+; jestlize ho
        #               nelze nalezt, vyvola se +VFormat::ConvertError+.
        #
        # Zalezi na konkretni implementaci komponenty, jake upravy musi provest
        # (pridat, smazat, zmodifikovat atributy, ...). Upravy mohou byt
        # destruktivni (pri konverzi nove komponenty zpet do puvodni verze
        # muzeme dostat odlisny obsah).
        #
        # Nezkonvertovatelne atributy jsou naklonovany, do jejich atributu
        # +error+ je ulozena chyba popisujici problem, a nasledne jsou zapsany
        # do +invalid_attributes+ novych komponent.
        #
        def to_version(new_ver, new_enc = nil)
            new_enc ||= VFormat.encoder(@name, new_ver) 

            raise ConvertError, "invalid version #{new_ver.inspect} or component #{@name}" unless 
                new_enc and new_enc.components[@name]
            
            return copy if @encoder == new_enc

            new_comp = new_enc.components[@name].allocate.init(@name, new_ver, new_enc)
            single_attrs = {}

            new_comp.convert_from(self)

            @attributes.each do |atr|
                if Attribute === atr 
                    # atribut
                    #
                    begin
                        if converter = new_comp.class.attribute_converter(atr)
                            # "proc" provadejici konverzi
                            #
                            new_comp.send(converter, self, atr)

                        elsif types = new_comp.attribute_value_types(atr.name)
                            # automaticka konverze podporovaneho atributu
                            #
                            raise ConvertError, "unsupported attribute type :#{atr.value_type}" unless
                                types.include?(atr.value_type)

                            unless new_comp.attribute_multi?(atr.name)
                                # atribut nemuze byt uveden nekolikrat
                                # 
                                raise ConvertError, "duplicated attribute" if single_attrs[atr.name]
                                single_attrs[atr.name] = true
                            end

                            new_comp.convert_attribute(atr)

                        elsif atr.name =~ /^X-/
                            # X-attribut
                            #
                            new_comp.convert_attribute(atr)

                        else
                            raise ConvertError, "unsupported attribute"
                        end

                    rescue ConvertError
                        atr = atr.copy
                        atr.error = $!
                        new_comp.invalid_attributes << atr
                    end

                else
                    # komponenta
                    #
                    new_comp << atr.to_version(new_ver, new_enc) if
                        new_enc.components[atr.name]
                end
            end

            # specificke upravy pro konkretni implementaci komponenty
            #
            new_comp.converted_from(self)
            new_comp
        end

        def convert_attribute(atr, new_type = nil) # :nodoc:
            convert_wrap_error do
                add(
                    atr.name,
                    atr.value,
                    {
                        :group => atr.group, 
                        :value_type => new_type || atr.value_type
                    }.update(atr.params)
                )
            end
        end

        def convert_from(orig) # :nodoc:
        end

        def converted_from(orig) # :nodoc:
        end

        def convert_wrap_error # :nodoc:
            begin
                yield
            rescue 
                raise ConvertError, $!.message, $!.backtrace
            end
        end

        # Vrati komponentu zakodovanou do rfc2425 ci pribuzneho formatu, tzn. do
        # retezce ve formatu VCARD, VEVENT, VTODO, .... Vrati neco jako:
        #
        # "BEGIN:VCARD\r\n
        # VERSION:2.1\r\n
        # N;Jan Becvar;;;\r\n
        # TEL;CELL:+420111111111\r\n
        # EMAIL;INTERNET:jan.becvar@solnet.cz\r\n
        # END:VCARD\r\n
        # "
        #
        # Muze vyvolat vyjimku +VFormat::EncodeError+ jestlize jsou hodnoty 
        # atributu nebo hodnoty parametru neslucitelne s vystupnim formatem.
        #
        # Jestlize je parametr +enc_instance+ instance tridy v atributu
        # +encoder+, potom se pouzije, jinak se vytvori novy encoder (slouzi pro
        # cachovani encoderu).
        #
        def encode(enc_instance = nil)
            result = []
            result << "BEGIN:" << @name << CRLF
            encode_attributes(
                result,
                enc_instance.instance_of?(@encoder) ? enc_instance : @encoder.new
            )
            result << "END:" << @name << CRLF
            result.join('')
        end
        
        alias to_s encode


        def encode_attributes(result, enc_instance)
            @attributes.each {|a| result << a.encode(enc_instance)}
        end

        # Vysledkem je pole s nazvama typu, ktere je mozne pouzit pro atribut
        # se jmenem +name+. Vrati nil, jestlize jmeno atributu neni
        # u teto komponenty zaregistrovano.
        #
        def attribute_value_types(name)
            self.class.attributes[name]
        end

        def attribute_default_value_type(name) #:nodoc:
            (self.class.attributes[name] || []).first
        end

        def attribute_multi?(name)
            self.class.multi_attributes[name]
        end
        
        # U :raw attributu se hodnoty dekoduji do +default_value_type+ nebo
        # jineho typu podle parametru VALUE (ktery se pote smaze).
        # 
        # Nezname atributy a atributy s chybnymi a nedekodovatelnymi hodnotami
        # jsou presunuty z +attributes+ do +invalid_attributes+. Pole
        # +invalid_attributes+ je na uplnem zacatku vyprazdneno.
        #
        def normalize_attributes
            @invalid_attributes.clear if invalid_attributes?
            single_attrs = {}

            @attributes.delete_if do |atr|
                begin
                    if Attribute === atr
                        name = atr.name
                        types = attribute_value_types(name)
                        
                        # je to podporovany atribut?
                        #
                        raise DecodeError, "unsupported attribute" unless 
                            types or name =~ /^X-/

                        # muze byt atribut uveden nekolikrat?
                        # 
                        unless attribute_multi?(name)
                            raise DecodeError, "duplicate attribute" if single_attrs[name]
                            single_attrs[name] = true
                        end

                        if atr.value_type? :raw
                            # pouzijeme typ uvedeny v parametru VALUE, jde-li
                            # to, jinak pouzijeme defaultni typ atributu
                            #
                            if a = atr['VALUE'].first and a = @encoder.encoded_to_value_type[a.upcase]
                                if types
                                    # vybere se prvni mezi moznymi typy atributu, jehoz enkodovana prezdivka
                                    # je uvedena ve VALUE
                                    # 
                                    type = types.find {|t| a.include?(t)}
                                else
                                    # "X-..." atribut - zkusime pouzit hodnotu z parametru VALUE
                                    #
                                    type = a.first
                                end
                            else
                                type = nil
                            end

                            atr.decode_raw_value(type || atr.default_value_type)
                            
                            # smazeme VALUE
                            #
                            atr.params.delete 'VALUE'
                        else
                            # zkontrolujeme, zda neni atribut nepodporovaneho typu
                            #
                            raise DecodeError, "invalid attribute type :#{atr.value_type}" if
                                types and !types.include?(atr.value_type)
                        end
                    else
                        # komponenta
                        #
                        atr.normalize_attributes
                    end

                    false

                rescue DecodeError
                    atr.error = $!
                    invalid_attributes << atr
                    true
                end
            end
        end

        # Pri volani nezname metody spravneho formatu/vzhledu zavola bud +[]+
        # nebo +add+ metodu.
        #
        # Mozne zpusoby volani:
        #
        #   c.NAME             - to same jako c[NAME]
        #   c.NAME = value     - to same jako c[NAME] = value
        #   c.NAME ...         - to same jako c.add(NAME, ...)
        #   c.NAME { ... }     - to same jako c.add(NAME) { ... }
        #   c.NAME ... { ... } - to same jako c.add(NAME, ...) { ... }
        #
        # Umoznuje tedy neco jako:
        #
        #   VFormat::VCARD.new do |c|
        #     c.N        = %w(Blekota Jan)
        #     c.F          'J. Blekota'
        #     c.CATEGORIES %w(12346 12347)
        #   end
        #
        # Pripadne:
        #
        #   VFormat::VCALENDAR.new do |c|
        #       c.VEVENT do |e|
        #           e.SUMMARY 'test'
        #           e.DTSTART [2007, 1, 1], 'TZID' => '/Europe/Prague'
        #       end
        #   end
        #
        def method_missing(id, *args, &block)
            if id.to_s =~ NAME_METHOD_MISSING_REGEXP
                if $2
                    self[$1] = args.first
                elsif block or !args.empty?
                    atr = new_attribute($1, *args, &block)
                    @attributes << atr
                    atr
                else
                    self[$1]
                end
            else
                super
            end
        end
    end


    # Komponenta, ktera v zakodovanem tvaru obsahuje atribut VERSION.
    #
    class VersionedComponent < Component
        def encode_attributes(result, enc_instance)
            result << "VERSION:" << @version << CRLF
            super
        end
    end

end

# vim: shiftwidth=4 softtabstop=4 expandtab
