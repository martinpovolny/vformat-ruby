#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
# = VFormat Ruby Library
# 
# == Author
# 
# Jan Becvar <jan.becvar@solnet.cz>
# 
# == License
# 
# This software is distributed under the Ruby License.
# 
# == About
# 
# VFormat knihovna je urcena pro praci s formatem RFC2425 a jeho modifikacemi.
# 
# Momentalne podporuje nasledujici formaty:
# 
# * rfc2425 (http://www.ietf.org/rfc/rfc2425.txt)
# * vCard 2.1 (http://www.imc.org/pdi/pdiproddev.html)
# * vCard 3.0 (http://www.ietf.org/rfc/rfc2426.txt)
# * vCalendar 1.0 (http://www.imc.org/pdi/pdiproddev.html)
# * iCalendar 2.0 (http://www.ietf.org/rfc/rfc2445.txt)
# 
# Formaty vCard 3.0 a iCalendar 2.0 vychazi z rfc2445. iCalendar 2.0 se mirne lisi
# od ostatnich. 
# 
# Formaty vCard 2.1 a vCalendar 1.0 se vzajemne shoduji, ale s rfc2425 jsou zcela
# nekompatibilni.
# 
# Knihovna pracuje s retezci v UTF-8 kodovani - do UTF-8 prevadi texty pri
# parsovani a toto kodovani predpoklada take pri dumpovani.
# 
# == Basic usage
# 
# Hlavnim stavebnim kamenem VFormatu je komponenta (+VFormat::Component+), ktera
# obsahuje seznam atributu (+VFormat::Attribute+) a dalsich (vlozenych) komponent.
# 
# Z +VFormat::Component+ jsou zdedeny predpripravene komponenty:
# 
# * +VFormat::VCARD30+
# * +VFormat::VCALENDAR20+
# * +VFormat::VEVENT20+
# ....
# 
# Predpripravene komponenty jsou v knihovnach 'vformat/icalendar' a
# 'vformat/vcard'. Po jejich "requirenuti" je mozne je snadno vyhledat
# podle jejich nazvu a verze pomoci +VFormat::[]+. 
#
# Priklad vytvoreni a naplneni komponenty VCALENDAR (v jeji defaultni verzi 2.0)
# a jeji zakodovani do retezce:
# 
# <code>
# require 'vformat/icalendar'
# 
# ical = VFormat['VCALENDAR'].new do |c|
#     c.VEVENT do |e|
#         e.DTSTART  '20060706T120000Z'
#         e.DTEND    [2006, 7, 6, 22, 0, 0, 'Z']
#         e.SUMMARY  'Meeting'
#         e.LOCATION 'Horní Třešňovec'
#     end
# end
# 
# print(ical.encode)
# </code>
# 
# Kde +VFormat['VCALENDAR']+ je to same jako +VFormat::VCALENDAR20+. Kdybychom
# pouzili +VFormat['VCALENDAR', '1.0']+, bylo by to stejne jako pristup primo k 
# +VFormat::VCALENDAR10+.
# 
# Vysledkem je:
# 
# <code>
# BEGIN:VCALENDAR
# VERSION:2.0
# BEGIN:VEVENT
# DTSTART:20060706T120000Z
# DTEND:20060706T220000Z
# SUMMARY:Meeting
# LOCATION:Horní Třešňovec
# END:VEVENT
# END:VCALENDAR
# </code>
# 
# Jestlize chceme komponentu prevest do formatu VCALENDAR 1.0, provedeme to nasledovne:
# 
# <code>
# ical = ical.to_version('1.0')
# print(ical.encode)
# </code>
# 
# Coz vypise:
# 
# <code>
# BEGIN:VCALENDAR
# VERSION:1.0
# BEGIN:VEVENT
# DTSTART:20060706T120000Z
# DTEND:20060706T220000Z
# SUMMARY:Meeting
# LOCATION;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:Horn=C3=AD T=C5=99e=C5=A1=
# =C5=88ovec
# END:VEVENT
# END:VCALENDAR
# </code>
# 
# Priklad dekodovani retezce a pristupu k atributum a parametrum atributu v
# komponente:
# 
# <code>
# require 'vformat/vcard'
# 
# str = <<EOT
# BEGIN:VCARD
# VERSION:3.0
# FN:Bjorn Jensen
# N:Jensen;Bjorn
# EMAIL;TYPE=INTERNET:bjorn@umich.edu
# TEL;TYPE=WORK,VOICE,MSG:+1 313 747-4454
# KEY;TYPE=X509;ENCODING=b:
#  dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK
# END:VCARD
# 
# BEGIN:VCARD
# VERSION:3.0
# FN:Jan Becvar
# N:Becvar;Jan
# END:VCARD
# EOT
# 
# vcards = VFormat.decode(str)  #=> Array
# vcard = vcards.first          #=> VFormat::VCARD
# vcard.FN                      #=> VFormat::Attribute
# vcard.FN.value                #=> "Bjorn Jensen"
# vcard.N.value                 #=> [["Jensen"], ["Bjorn"]]
# vcard.KEY.value               #=> "this could be \nmy certificate\n"
# vcard.TEL.TYPE                #=> ["WORK", "VOICE", "MSG"]
# vcard.NOTEXIST.value          #=> nil
# </code>
# 
# Komponentu muzeme zmodifikovat a vydumpovat v jinem formatu:
# 
# <code>
# vcard.N.value = ['X', 'Y', 'Z']
# vcard.N['X-PARAM'] = 'custom parameter'
# vcard.add 'NOTE', 'text with UTF-8: ěščžčř'
# vcard.TEL.TYPE << 'HOME'
# 
# print(vcard.to_version('2.1').encode)
# </code>
# 
# Vysledek:
# 
# <code>
# BEGIN:VCARD
# VERSION:2.1
# FN:Bjorn Jensen
# N;X-PARAM=custom parameter:X;Y;Z
# EMAIL;INTERNET:bjorn@umich.edu
# TEL;WORK;VOICE;MSG;HOME:+1 313 747-4454
# KEY;X509;ENCODING=BASE64:
#  dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK
# 
# NOTE;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:text with UTF-8: =C4=9B=C5=A1=
# =C4=8D=C5=BE=C4=8D=C5=99
# END:VCARD
# </code>
# 
# == Advanced usage
# 
# Hodnoty atributu mohou mit ruzne typy a kazdy z nich se specialnim zpusobem
# koduje a dekoduje.
# 
# Preddefinovane komponenty (napr. +VFormat::VEVENT20+) v sobe maji zaregistrovane
# nazvy znamych atributu a jejich povolenych typu. Napr. atribut
# <code>DTSTART</code> muze byt typu <code>:date_time</code> nebo typu
# <code>:date</code>. Pri pristupu k hodnote pak v pripade nekolika soucasne
# povolenych typu musime provest jeho kontrolu:
# 
# <code>
# if vevent.DTSTART.date?
#     do_something_with_date(vevent.DTSTART.value)
# else
#     do_something_with_date_time(vevent.DTSTART.value)
# end
# </code>
# 
# Jestlize atribut <code>DTSTART</code> v komponente existuje, potom je kod
# <code>vevent.DTSTART.date?</code> shodny s kodem 
# <code>vevent.DTSTART.value.type == :date</code> a s kodem
# <code>vevent.DTSTART.value_type?(:date)</code>.
# 
# Dalsim prikladem muze byt atribut <code>PHOTO</code>, u ktereho v nasledujicim
# prikladu zkontrolujeme, zda je typu <code>:binary</code> a zda ma navic nastaveny
# parametr <code>TYPE</code> na hodnotu <code>JPEG</code>:
# 
# <code>
# photo = vcard.PHOTO
# jpeg_data = photo.value if photo.binary? and photo.type? 'JPEG'
# </code>
# 
# Vytvoreni atributu <code>PHOTO</code> s nestandartnim typem hodnoty :uri:
# 
# <code>
# vcard.PHOTO 'http://test/photo.gif', :value_type => :uri
# </code>
# 
# Objekty vracene metodou +VFormat::Attribute#value+ jsou vetsinou zakladni datove
# typy (String, Array) rozsirene o nekolik metod (modul +VFormat::Value::Mixin+). 
# Napr. o metodu +encode+:
# 
# <code>
# vevent.DTSTART.value.encode #=> "20071220T120000Z"
# </code>
# 
# Pro porovnani <code>VFormat::Attribute#encode</code> vraci:
# 
# <code>
# vevent.DTSTART.encode #=> "DTSTART:20071220T120000Z\r\n"
# </code>
# 
# Atributy s nazvem zacinajicim na <code>X-</code> jsou defaultne typu :text.
# 
# Pri nastavovani hodnot atributu je nutne bud primo specifikovat typ pomoci metod
# <code>VFormat::Attribute#<type>=</code>, nebo pouzit metodu
# <code>VFormat::Attribute#value=</code>, ktera nastavi hodnotu v defaultnim typu
# pro dany atribut.
# 
# <code>
# dtstart = vevent.DTSTART
# dtstart.value = '20071220T100000'
# dtstart.value #=> "#<struct VFormat::Value::DateTime year=2007, month=12, day=20, ...>
# dtstart.value = '20071220' #=> vyvola: ArgumentError: invalid date-time representation
# dtstart.date  = '20071220'
# dtstart.value #=> #<struct VFormat::Value::Date year=2007, month=12, day=20>
# dtstart.date  = [2007, 12, 19]
# dtstart.value #=> #<struct VFormat::Value::Date year=2007, month=12, day=19>
# dtstart.encode #=> "DTSTART;VALUE=date:20071219\r\n"
# </code>
# 
# Jak je z prikladu videt, hodnoty se mohou inicializovat ruznym zpusobem (napr.
# retezcem <code>'20071220'</code>, polem <code>[2007, 12, 19]</code>, atd.) - zalezi
# pouze na tom, co vse dokaze zpracovat metoda +new+ u tridy implementujici typ
# nastavovane hodnoty (tedy v tomto pripade trida +VFormat::Value::DateTime+ a
# +VFormat::Value::Date+).
# 
# Vice viz. metody:
# 
# * +VFormat::Attribute.new+
# * +VFormat::Attribute#value+
# * +VFormat::Attribute#value=+
# * +VFormat::Attribute#with_value+
# * +VFormat::Attribute#params+
# * +VFormat::Attribute#default_value_type+
# * +VFormat::Attribute#[]+
# * +VFormat::Attribute#[]=+
# * +VFormat::Component.new+
# * +VFormat::Component#encode+
# * +VFormat::Component#[]+
# * +VFormat::Component#[]=+
# * +VFormat::Component#add+
# * +VFormat.decode+
# 
# dale viz. tridy v modulu +VFormat::Value+ a definice preddefinovanych komponent
# (+VFormat::VCARD30+, +VFormat::VEVENT20+, ... ) ve zdrojovych kodech 
# (TODO - dostat do RDoc).
#

module VFormat
    class Error < RuntimeError 
    end
    
    class DecodeError < Error
    end

    class EncodeError < Error
    end

    class ConvertError < Error
    end


    CRLF = "\r\n"

    # Spec: name = 1*(ALPHA / DIGIT / "-")
    # Note: added '_' to allowed because its produced by Notes - X-LOTUS-CHILD_UID
    #
    NAME_PATTERN = '[-A-Za-z0-9_]+'
    NAME_METHOD_MISSING_REGEXP = /\A([A-Z][-A-Z0-9_]*)(=)?\z/
        
    # Spec: param-value = ptext / quoted-string
    #
    PVALUE_PATTERN = '(?:"[^"]*"|[^";:,]+)'
    PVALUE_REGEXP  = /"([^"]*)"|([^";:,]+)/

    # Spec: param = name "=" param-value *("," param-value)
    # Note: v2.1 allows a TYPE or ENCODING param-value to appear without the TYPE=
    # or the ENCODING=.
    #
    PARAM_PATTERN = ";#{NAME_PATTERN}(?:=#{PVALUE_PATTERN}(?:,#{PVALUE_PATTERN})*)?"
    PARAM_REGEXP  = /;(#{NAME_PATTERN})(?:=(#{PVALUE_PATTERN}(?:,#{PVALUE_PATTERN})*))?/o

    # V3.0: contentline  =   [group "."]  name *(";" param) ":" value
    # V2.1: contentline  = *( group "." ) name *(";" param) ":" value
    #
    LINE_START_PATTERN = "\\A((?:#{NAME_PATTERN}\\.)+)?(#{NAME_PATTERN})"
    LINE_REGEXP    = /#{LINE_START_PATTERN}((?:#{PARAM_PATTERN})+)?:(.*)\z/o
    LINE_QP_REGEXP = /#{LINE_START_PATTERN}(?:#{PARAM_PATTERN})*;(?:ENCODING=)?QUOTED-PRINTABLE[;:]/oi

    # date = date-fullyear ["-"] date-month ["-"] date-mday
    # date-fullyear = 4 DIGIT
    # date-month    = 2 DIGIT
    # date-mday     = 2 DIGIT
    #
    DATE_PATTERN = "(\\d\\d\\d\\d)-?(\\d\\d)-?(\\d\\d)"
    DATE_REGEXP  = /\A#{DATE_PATTERN}\z/o
    
    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour    = 2 DIGIT
    # time-minute  = 2 DIGIT
    # time-second  = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone    = "Z" / time-numzone
    # time-numzome = sign time-hour [":"] time-minute
    #
    TIME_PATTERN = "(\\d\\d):?(\\d\\d):?(\\d\\d(?:\.\\d+)?)(Z|[-+]\\d\\d:?\\d\\d)?"
    TIME_REGEXP  = /\A#{TIME_PATTERN}\z/o

    # time-date = date "T" time
    #
    DATE_TIME_REGEXP = /\A#{DATE_PATTERN}T#{TIME_PATTERN}\z/o

    # jak mohou vypadat integery
    #
    INT_REGEXP    = /\A[-+]?\d+\z/
    POSINT_REGEXP = /\A\+?\d+\z/

    # nazvy dnu v tydnu
    #
    WEEKDAYS = [ :mo, :tu, :we, :th, :fr, :sa, :su ]

    # setrime pamet:
    #  
    BINARY_OR_URL_OR_CID = [:binary, :url, :cid]
    DATE_TIME_OR_DATE    = [:date_time, :date]

end # VFormat


require 'enumerator'
require 'vformat/attribute'
require 'vformat/value'
require 'vformat/encoder'
require 'vformat/component'


module VFormat
    # inicializace atributu v tride
    # 
    @encoders = {}

    class << self # metody tridy

        # [Hash] Zaregistrovane defaultni encodery pro jednotlive nazvy
        # komponent. Format:
        #   {
        #       'VCARD'          => VFormat::Encoder::VCARD30,
        #       ...
        #   }
        #
        attr_accessor :encoders

        # Najde tridu komponenty pro zadany nazev a verzi. Vraci nil, jestlize se
        # ji nalezt nepodarilo. Neni-li zadana verze, znaci to defaultni
        # komponentu pro dany nazev:
        #
        #   VFormat['VCALENDAR'].new do |c|
        #       ...
        #   end
        #
        # To same jako:
        #
        #   VFormat::VCALENDAR20.new do |c|
        #       ...
        #   end
        #
        # Vyhledani podle nazvu a verze:
        #
        #   VFormat['VCALENDAR', '1.0'].new do |c|
        #       ...
        #   end
        #
        # To same jako:
        #
        #   VFormat::VCALENDAR10.new do |c|
        #       ...
        #   end
        # 
        #  TODO nevracel nil, ale vyvolat vyjimku
        #
        def [](name, version = nil)
            return nil unless c = @encoders[name]

            if version
                while c.version != version
                    return nil unless c = c.previous_version
                end
            end

            c.components[name]
        end

        # Najde encoder pro zadany nazev komponenty a verzi. Vraci nil, jestlize se
        # ho nalezt nepodarilo. Neni-li zadana verze, znaci to defaultni
        # encoder pro dany nazev.
        # 
        def encoder(name, version = nil)
            return nil unless e = @encoders[name]

            if version
                while e.version != version
                    return nil unless e = e.previous_version
                end
            end

            e
        end

        # Rozparsuje retezec do neceho takovehodle:
        #
        # { 
        #    :attributes => [
        #        {
        #           :name       => 'VCARD',
        #           :version    => '2.1',
        #           :attributes => [
        #               ['N:...'],
        #               ['ADR:..', '...'], # byl zapsan na vice radcich
        #               ...
        #           ]
        #        },
        #        ...
        #     ]
        # }
        #
        def parse(str)
            root         = { :attributes => [] }
            path         = []  # zanoreni do subcomponent
            current_comp = root

            attr_line    = nil # rozpracovany atribut
            attr_line_qp = false

            add_attr = proc do
                line = attr_line.join('')
                line.delete!(" \t") 

                case line
                when /\ABEGIN:(.*)\z/i
                    c = { :name => $1.upcase, :attributes => [] }

                    current_comp[:attributes] << c
                    path << current_comp
                    current_comp = c

                when /\AEND:(.*)\z/i
                    current_comp = path.pop if current_comp[:name] == $1.upcase

                when /\AVERSION:(.*)\z/i
                    current_comp[:version] = $1

                when ''
                    # povolujeme prazdne radky
                    #
                else
                    current_comp[:attributes] << attr_line
                end
            end

            # split +str+ on \r\n or \n to get the lines and unfold continued lines
            # (they start with ' ' or \t)
            #
            str.split(/(?:\r\n|\n)/m).each do |line|
                line.chomp!

                if attr_line
                    # pokracuje rozpracovany atribut na tomto radku?
                    #
                    if attr_line_qp and attr_line.last[-1] == ?=
                        # pokracovani QP textu
                        #
                        attr_line.last.slice!(-1)
                        attr_line << line
                        next
                    end

                    if line =~ /\A[ \t]/
                        # VCARD21, VCAL10 zachovavaji prvni mezeru/tabulator na novem radku,
                        # ostatni ji zahazuji; radky proto nyni nespojime
                        #
                        attr_line << line
                        next
                    end

                    # nepokracuje - pridame rozpracovany atribut
                    #
                    add_attr.call
                end

                # zacatek noveho atributu
                #
                attr_line    = [line]
                attr_line_qp = (line =~ LINE_QP_REGEXP)
            end

            add_attr.call if attr_line
            root
        end


        # Rozparsuje retezec +str+ ve formatu rfc2425 ci pribuznem a vrati v
        # poli vsechny +VFormat::Component+, ktere jsou v nem za sebou
        # zakodovane.
        #
        # Almost nothing is considered a fatal error. Always tries to return
        # something. Muze ale vratit prazdne pole napr. v pripade prazdneho retezce.
        #
        # Chybne radky zapisuje do komponent do pole +invalid_lines+. 
        #
        # Na rozparsovanych atributech se neprovadi zadne upravy, jejich hodnoty
        # jsou typu :raw a obsahuji vsechny puvodni parametry jak jsou zapsane
        # ve +str+. Pouze maji nastaven +default_value_type+ na hodnotu
        # odpovidajici nazvu daneho atributu.
        #
        # Format +str+ je automaticky detekovan pomoci nazvu komponenty a jejiho
        # VERSION attributu. Jestlize VERSION atribut chybi, potom se pouzije
        # parametr +version+. Jestlize neni nastaven ani +version+, pouzije se
        # defaultni verze pro parsovanou komponentu.
        #
        # Jestlize neni zadany +encoder+, potom se pokusi pomoci
        # +VFormat::encoder+, nazvu a verze komponenty nalezt a pouzit spravny
        # encoder.
        #
        def decode_raw(str, version = nil, encoder = nil)
            parse(str)[:attributes].delete_if do |atr| 
                Array === atr # atribut na nejvyssi urovni nema co delat - preskocime ho
            end.map do |par_comp|
                par_comp[:version] ||= version

                (
                    encoder ||
                    self.encoder(par_comp[:name], par_comp[:version]) ||
                    @encoders[par_comp[:name]] ||
                    Encoder::RFC2425
                ).decode_parsed(par_comp)
            end
        end

        # Rozparsuje retezec +str+ pomoci +decode_raw+ a pote na vsech
        # komponentach spusti +normalize_attributes+.
        #
        # Hodnoty atributu jsou prevedeny do UTF-8 a do spravnych typu. Jsou
        # promazany parametry 'ENCODING', 'CHARSET', a dalsi (viz.
        # +VFormat::Component::normalize_attributes+).
        #
        # Chybne radky jsou zapsany u komponent do pole +invalid_lines+, chybne
        # atributy do pole +invalid_attributes+.
        #
        # Argumenty a navratove hodnoty viz. +VFormat::decode_raw+.
        #
        def decode(str, version = nil, encoder = nil)
            comps = decode_raw(str, version, encoder)
            comps.each {|comp| comp.normalize_attributes}
            comps
        end

    end # VFormat << self

end # VFormat


# vim: shiftwidth=4 softtabstop=4 expandtab
