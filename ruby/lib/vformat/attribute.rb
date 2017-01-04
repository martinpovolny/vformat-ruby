#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#

module VFormat

    # Attribut v komponente. Napr. SUMMARY ve VEVENTu.
    #
    class Attribute
        CRLF = "\r\n"
        
        # jaky nazev parametru se ma pouzit pro bezrovnitkove parametry 
        # (napr. "TEL;WORK:111")
        #
        PARAM_REAL_NAME = { 'QUOTED-PRINTABLE' => 'ENCODING', 'BASE64' => 'ENCODING' }
        PARAM_REAL_NAME.default = 'TYPE'

        # [nil|String] attribute group; may be nil if attribute hasn't group;
        # je uppercase
        #
        # Spec: The group construct is used to group related attributes
        # together.  The group name is a syntactic convention used to indicate
        # that all type names prefaced with the same group name SHOULD be
        # grouped together when displayed by an application. It has no other
        # significance.  
        #
	attr_accessor :group
        
        # [String] jmeno atributu velkymi pismeny
        #
	attr_accessor :name   

        # [Hash] Parametry atributu ve formatu: { 'TYPE' => ['WORK', 'HOME'] }.
        # Vsechny klice jsou velkymi pismeny, hodnoty jsou pole stringu. 
        # Vsechny hodnoty parametru 'TYPE' jsou velkymi pismeny. 
        # Parametry ENCODING, CHARSET a VALUE se resi jinak a nemely by se v
        # parametrech vyskytovat (jsou ignorovany pri +encode+).
        #
	attr_reader :params
        
        # Obsahuje hodnotu atributu, coz je objekt s interfacem
        # +VFormat::Value::Mixin+.
        #
        # Pro kontrolu typu pred pristupem k hodnote je mozne pouzit metody +raw?+,
        # +text?+, +list?+, ... (viz. objekty v modulu +VFormat::Value+).
        #
        # Pro nastaveni hodnoty i typu soucasne je mozne pouzit metody +raw=+,
        # +text=+, +list=+, ...
        #
        # Priklady:
        #
        #   atr = vcard.CATEGORIES('A,B,C', :value_type => :raw)  #=> atr
        #   atr.value                                #=> 'A,B,C'
        #   atr.value.type                           #=> :raw
        #   atr.value.class                          #=> VFormat::Value::Raw
        #   atr.decode_raw_value :text_list          #=> atr
        #   atr.value                                #=> ['A', 'B', 'C']
        #   atr.value.type                           #=> :text_list
        #   atr.value.class                          #=> VFormat::Value::TextList
        #   atr.list?                                #=> true
        #   atr.value.encode                         #=> 'A,B,C'
        #
        #   atr.structured = %w(A B C)
        #   atr.value                                #=> [['A'], ['B'], ['C']]
        #   atr.value.class                          #=> VFormat::Value::Structured
        #   atr.structured?                          #=> true
        #
        #   atr = vcal.CATEGORIES(%w(hello word), 'CHARSET' => 'UTF-8') #=> +VFormat::Attribute+
        #   atr.value                                #=> ["hello", "word"]
        #   atr.value.encode                         #=> "hello,word"
        #   atr.encode                               #=> "CATEGORIES:hello,word\r\n"
        #   atr.encode(VFormat::Encoder::VCAL10.new) #=> "CATEGORIES;CHARSET=UTF-8:hello,word\r\n"
        #   atr.value << 'one' << 'two'
        #   atr.value.encode                         #=> "hello,word,one,two"
        #   atr.value.encode(VFormat::Encoder::VCAL10) #=> "hello,word,one,two"
        # 
	attr_reader :value

        # Nastavi +value+ na +val+, coz je cokoliv, co umi zpracovat +new+
        # metoda ve tride implementujici typ nastaveny v +default_value_type+.
        # Z +val+ se tedy vyrobi novy objekt, ktery je pote ulozen ve +value+.
        #
        def value=(val)
            @value = @encoder.value_type_class(@default_value_type).new(val)
        end

        # [Symbol] Nazev defaultniho typu hodnoty. Ovlivnuje automatickou
        # konverzi typu pri volani metody +value=" a zacleneni parametru VALUE
        # pri +encode+. Default je :text.
        #
        attr_accessor :default_value_type

        # [VFormat::Encoder class] Trida encoderu, ktery se pouziva pro kodovani
        # tohoto atributu. Defaultne je +VFormat::Encoder::RFC2425+.
        #
        attr_accessor :encoder

        # [nil|Exception] Jestlize se tento atribut nachazi v poli
        # +VFormat::Component::invalid_attributes+, ma nastaven +error+ na
        # +Exception+ kvuli kteremu tam byl umisten (vetsinou to je
        # nejaky +VFormat::DecodeError+).
        # 
        attr_accessor :error

        
        # Vytvori a vrati +VFormat::Attribute+ rozkodovanim retezce v 
        # rfc2425 ci pribuznem formatu.
        # 
        # Argumenty:
        #  +line+ - [String] retezec tvaru:
        #             [<group>.]<name>;<pname>=<pvalue>,<pvalue>:<value>
        #           Jiz musi byt provedeny unfolding, tzn. nemuze obsahovat "\n"
        #           znaky. Hodnota muze byt ale stale zakodovana pomoci B64 nebo QP.
        #
        # Jestlize +line+ neni dekodovatelny, vyvola +VFormat::DecodeError+.
        # Jinak vrati novy dekodovany atribut s +value+ typu :raw.
        #
        def self.decode(line, encoder = Encoder::RFC2425)
            raise DecodeError, "invalid line format" unless line =~ LINE_REGEXP

            args = { :encoder => encoder, :value_type => :raw }
            args[:group], name, params, value = $1, $2.upcase, $3, $4

            # nedovolime nazvy attributu stejne jako nazvy komponent
            #
            raise DecodeError, "attribute with name of registered component: #{name}" if
                encoder.components[name]

            # group
            #
            if args[:group]
                args[:group].upcase!
                args[:group].chomp!('.')
            end

            # parametry
            #
            enc = nil

            if params
                params.scan(PARAM_REGEXP) do
                    pname, pvalues = $1.upcase, $2

                    if pvalues
                        pvalues.upcase! if pname == 'TYPE'
                    else
                        # parametr bez "=PVALUE"
                        #
                        pvalues = pname
                        pname   = PARAM_REAL_NAME[pname]
                    end

                    p = (args[pname] ||= [])
                    pvalues.scan(PVALUE_REGEXP) do
                        p << ($1 || $2).force_encoding_vformat('UTF-8')
                    end
                end

                # kodovani
                #
                if enc = args.delete('ENCODING')
                    case (enc || []).first
                    when /^b|base64$/i
                        value.delete!(" \t")
                        value = value.unpack('m').first
                        enc = :b64
                    when /^quoted-printable$/i
                        value = value.unpack("M").first
                        enc = :qp
                    else
                        enc = nil
                    end
                end
            end


            new(
                name, 
                [
                    value, 
                    enc,
                    (args.delete('CHARSET') || []).first || encoder.default_charset
                ],
                args
            )
        end
        
        # call-seq:
        # Attribute.new(name, value) {|attribute| ... } #=> attribute
        # Attribute.new(name, value, args) {|attribute| ... } #=> attribute
        #
        # Argumenty:
        #   +name+    - [String] musi byt velkymi pismeny
        #   +value+   - hodnota atributu, coz je +VFormat::Attribute+ nebo
        #               cokoliv, co umi zpracovat trida implementujici typ
        #               zadany pomoci klicu :value_type nebo :default_value_type
        #               v +args+ parametru. Viz. +value=+.
        #
        #   +args+    - [Hash] muze obsahovat nasledujici klice:
        #       :value_type - [Symbol] typ hodnoty pouzity pri 
        #                 zpracovani +value+ (napr. :binary); jestlize neni
        #                 zadany, potom se pouzije hodnota v :default_value_type
        #                 nebo typ :text; jestlize je zadane 
        #       :group, :encoder, :default_value_type - nastavi odpovidajici atributy
        #       'PNAME' - [String] definice parametru, 
        #                 napr. 'TYPE' => 'WORK' nebo 'TYPE' => %w(WORK CELL)
        #
        # Priklad:
        #
        #   VFormat::Attribute.new('SUMMARY', 'hello') #=> VFormat::Attribute
        #
        #   VFormat::Attribute.new('PHOTO', '...', :value_type => :binary, 'TYPE' => 'GIF')
        #       #=> VFormat::Attribute
        #
        #   VFormat::Attribute.new('TEL', %w(112 344), :value_type => :text_list, :group => 'A', 'TYPE' => %w(HOME WORK))
        #       #=> VFormat::Attribute
        #
        def initialize(name, value, args = nil)
            @name = name

            if Attribute === value
                @group              = value.group
                @encoder            = value.encoder
                @default_value_type = value.default_value_type
                @params             = Marshal.load(Marshal.dump(value.params))
                @value              = value.value.copy
            else
                @group              = nil
                @encoder            = Encoder::RFC2425
                @default_value_type = :text
                @params             = {}
                value_type          = nil
            end

            if args
                args.each do |k, v| 
                    case k
                    when :value_type
                        value_type = v
                    when :group
                        @group = v
                    when :encoder
                        @encoder = v
                    when :default_value_type
                        @default_value_type = v
                    when String
                        @params[k] = Array === v ? v.dup : Array(v)
                    else
                        raise ArgumentError, "invalid argument `#{k}'"
                    end
                end
            end

            @value ||= @encoder.value_type_class(value_type || @default_value_type).new(value)

            yield(self) if block_given?

            self
        end
       
        # Zkratka pro +value.type == type+.
        #
        def value_type?(type)
            @value.type == type
        end

        # Vrati nazev typu +value+. To same jako +value.type+, ale funguje i u
        # +VFormat::NIL_ATTRIBUTE+.
        #
        def value_type
            @value.type
        end
        
        # Prevade +value+, ktery musi byt typu :raw, na typ +type+. Jestlize je
        # +value+ jiz typu +type+, potom nedela nic.
        #
        # Vraci +self+. 
        #
        # Argumenty:
        #  +type+ - [Symbol] zaregistrovany typ
        #           (napr. :raw, :string, :text, :text_list, :time, ...),
        #           viz. objekty v modulu VFormat::Value
        #
        #  Priklad:
        #
        #  summary = vcal.SUMMARY('hello\\, word', :value_type => :raw) #=> +VFormat::Attribute+
        #  summary.value.class #=> VFormat::Value::Raw
        #  summary.decode_raw_value(:text) #=> summary
        #  summary.value #=> "hello, word"
        #  summary.value.class #=> VFormat::Value::Text
        #
        def decode_raw_value(type)
            unless @value.type == type
                raise TypeError, "already decoded value to type :#{@value.type}" unless 
                    Value::Raw === @value

                @value = @encoder.value_type_class(type).decode_raw(@value, @encoder)
            end

            self
        end

        # deep clone
        #
        def copy
            Marshal.load(Marshal.dump(self))
        end
        
        # Is one of the values of the TYPE parameter of this attribute +type+?
        # False if there is no TYPE parameter.
        #
        # TYPE parameters are used for general categories, such as
        # distinguishing between an email address used at home or at work.
        #
        # Argument +type+ musi byt velkymi pismeny.
        #
        # Priklad:
        #  vcard.TEL.type? 'HOME' #=> true
        #
        def type?(type)
            self['TYPE'].include? type
        end

        # Zavola predany blok s parametrem +value+. U +VFormat::NIL_ATTRIBUTE+
        # se blok nezavola, takze je mozne podminit provedeni kodu pouze u
        # atributu, ktery v komponente skutecne existuje:
        #
        #   vcard.EMAIL.with_value {|mail| puts(mail)}
        #
        # Tento priklad vypise mail kontaktu, jestlize ho kontakt obsahuje,
        # jinak neudela nic.
        #
        # Vraci navratovou hodnotu bloku.
        #
        def with_value
            yield(@value)
        end
       
        # Vraci +true+ (u +VFormat::NIL_ATTRIBUTE+
        # vraci +false+).
        #
        def value?
            true
        end

        # Obsahuje atribut neprazdny parametr s nazvem +name+?
        #
        # Priklad:
        #  vcard.PHOTO.param? 'VALUE'
        #
        def param?(name)
            ! self[name].empty?
        end

        # Vraci pole hodnot parametru +param_name+.  Neexistoval-li dosud dany
        # parametr, nejprve ho vytvori s prazdnym polem hodnot.
        #
        #   +param_name+ - [String] jmeno parametru velkymi pismeny
        #
        # Vraci pole, ktere primo nalezi do attributu, a jeho modifikaci se tedy
        # meni primo attribut.
        #
        # Priklady:
        #
        #   attr['CN'].first
        #   attr['TYPE'] << 'WORK'
        #
        def [](param_name)
            @params[param_name] ||= []
        end

        # call-seq:
        # attr[param_name] = string  #=> string
        # attr[param_name] = array_of_strings #=> array_of_strings
        # attr[param_name] = nil  #=> nil
        #
        # Nahradi hodnoty parametru +param_name+. 
        #
        #   +param_name+ - [String] jmeno parametru velkymi pismeny
        #
        # Priklady:
        #
        # attr['TYPE'] = 'WORK' # to same jako:
        # attr['TYPE'] = ['WORK']
        #
        # attr['TYPE'] = nil # to same jako:
        # attr['TYPE'] = []
        # 
        def []=(param_name, param_values)
            @params[param_name] = Array(param_values)
            param_values
        end

        # call-seq:
        # attr.add_param(param_name, param_val1, ...) #=> attr
        #
        # Prida hodnoty do parametru +param_name+. 
        #
        #   +param_name+ - [String] jmeno parametru velkymi pismeny
        #
        # Priklady:
        #
        # attr.add_param('TYPE', 'WORK', 'VOICE') # to same jako:
        # attr['TYPE'] << 'WORK' << 'VOICE'
        #
        # Vraci self.
        # 
        def add_param(param_name, *param_values)
            self[param_name].concat(param_values)
            self
        end

        def ==(other)
            Attribute    === other and 
            @group        == other.group and 
            @name         == other.name and 
            @value.encode == other.value.encode and
            @params.reject {|k, v| v.empty?} == other.params.reject {|k, v| v.empty?}
        end

        # Vrati atribut zakodovany do retezce urceneho pro vlozeni do rfc2425 ci
        # pribuzneho formatu. Vysledny retezec muze byt zalamany na nekolik
        # radku a na konci bude obsahovat CRLF sekvenci. Bude priblizne tvaru:
        # 
        #  [<group>.]<name>;<pname>=<pvalue>,<pvalue>:<value>
        #
        # Jestlize je parametr +enc_instance+ instance tridy +encoder+, potom se
        # pouzije, jinak se vytvori novy encoder.
        #
        #
        def encode(enc_instance = nil)
            (
                enc_instance.instance_of?(@encoder) ? enc_instance : @encoder.new
            ).encode(self)
        end

        alias to_s encode

        # Pri volani nezname metody spravneho formatu/vzhledu zavola bud +[]+,
        # +[]=+ nebo +add_param+ metodu.
        #
        # Mozne zpusoby volani:
        #
        #   a.PNAME              - to same jako  a[PNAME]
        #   a.PNAME = pvalue     - to same jako  a[PNAME] = value
        #   a.PNAME = [pvalues]  - to same jako  a[PNAME] = [pvalues]
        #   a.PNAME pval1, pval2... - to same jako  a.add_param NAME, pval1, pval2, ...
        #
        # Vraci +self+.
        # 
        # Umoznuje tedy neco jako:
        #
        #   a.TYPE 'WORK', 'VOICE' #=> a
        #   a.TYPE = 'WORK' #=> 'WORK'
        #   ...
        #
        def method_missing(id, *args)
            if id.to_s =~ NAME_METHOD_MISSING_REGEXP
                if $2
                    self[$1] = args.first
                elsif !args.empty?
                    add_param($1, *args)
                else
                    self[$1]
                end
            else
                super
            end
        end

    end # VFormat:Attribute


    # Trida pro objekt +VFormat::NIL_ATTRIBUTE+, ktery reprezentuje neexistujici
    # atribut (viz. +VFormat::Component#[]+).
    # 
    class NilAttribute < Attribute
        def initialize
            @name               = nil
            @group              = nil
            @value              = nil
            @default_value_type = :text
            @params             = {}.freeze
            freeze
        end

        # Nedela nic a vraci nil.
        #
        def with_value
            nil
        end

        # Vraci +false+.
        #
        def value?
            false
        end

        # Vraci +false+.
        #
        def value_type?(type)
            false
        end

        # Vraci +nil+.
        #
        def value_type
            nil
        end

        # Vraci nove prazdne pole.
        #
        def [](param_name)
            []
        end

    end # VFormat::NilAttribute

    NIL_ATTRIBUTE = NilAttribute.new
    
end # VFormat

# vim: shiftwidth=4 softtabstop=4 expandtab
