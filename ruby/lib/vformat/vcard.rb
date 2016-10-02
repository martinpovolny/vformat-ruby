#
#  Copyright (c) 2007 Jan Becvar <jan.becvar@solnet.cz>
#  Copyright (c) 2007 soLNet, s.r.o. 
#
require 'vformat'

module VFormat

    class VCARD21 < VersionedComponent
        default_name 'VCARD'

        # ADR:
        # Components: the post office box; the extended address; the street
        #             address; the locality (e.g., city); the region (e.g.,
        #             state or province); the postal code; the country name
        #
        def_attribute 'ADR',        :structured,            :multiple => true
        def_attribute 'AGENT',      :text
        def_attribute 'BDAY',       :date
        def_attribute 'EMAIL',      :text,                  :multiple => true
        def_attribute 'FN',         :text
        def_attribute 'GEO',        :geo
        def_attribute 'KEY',        BINARY_OR_URL_OR_CID,   :multiple => true
        def_attribute 'LABEL',      :text,                  :multiple => true
        def_attribute 'LOGO',       BINARY_OR_URL_OR_CID
        def_attribute 'MAILER',     :text
 
        # N:
        # Components: Family Name, Given Name, Additional Names, Honorific Prefixes, and
        #             Honorific Suffixes. 
        #
        #
        def_attribute 'N',           :structured
        def_attribute 'NOTE',        :text

        # ORG: 
        # Components: the organization name, followed by one or more levels
        #             of organizational unit names
        #
        def_attribute 'ORG',         :structured
        def_attribute 'PHOTO',       BINARY_OR_URL_OR_CID # TODO - :convertor
        def_attribute 'REV',         :date_time,            :convertor => :convert_time
        def_attribute 'ROLE',        :text
        def_attribute 'SOUND',       BINARY_OR_URL_OR_CID
        def_attribute 'TEL',         :string,               :multiple => true
        def_attribute 'TITLE',       :text
        def_attribute 'TZ',          :utc_offset
        def_attribute 'UID',         :text
        def_attribute 'URL',         :uri,                  :multiple => true


        def convert_time(old_comp, atr) #:nodoc:
            convert_attribute(atr, :date_time)
        end
    end


    class VCARD30 < VCARD21
        binary = [:binary, :uri]

        def_attribute 'AGENT',       [:text, :uri]
        def_attribute 'BDAY',        [:date, :date_time]
        def_attribute 'CATEGORIES',  :text_list,             :multiple => true
        def_attribute 'CLASS',       :text
        def_attribute 'KEY',         [:binary, :text],       :multiple => true
        def_attribute 'LOGO',        binary
        def_attribute 'NICKNAME',    :text_list
        def_attribute 'PHOTO',       binary
        def_attribute 'PRODID',      :text
        def_attribute 'REV',         DATE_TIME_OR_DATE
        def_attribute 'SORT-STRING', :text
        def_attribute 'SOUND',       binary
    end


    #
    # Encoders
    #
    
    module Encoder
        class VCARD21 < PreRFC
            version       '2.1'
            def_component VFormat::VCARD21
        end

        class VCARD21Win < PreRFC
            version       '2.1'
            def_component VFormat::VCARD21

            def detect_encoding(raw_value)
                if @charset.nil?
                    @params["CHARSET"] = 'windows-1250'
                elsif @charset == false
                    @params.delete "CHARSET"
                else
                    @params["CHARSET"] = @charset
                end
            end

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

                @params.each do |pname, pvalues|
                    pvalues = Array(pvalues)
                    encode_param(pname, pvalues) unless pvalues.empty?
                end

                result << ':'
                value = raw_value
                if (@params['CHARSET'] and @params['CHARSET'] != 'UTF-8')
                    case value
                    when Array
                        value.map! { |t| SasIconv::from_utf8(@params['CHARSET'],t) }
                    else
                        value = SasIconv::from_utf8(@params['CHARSET'], raw_value) 
                    end
                end
                append_raw_value(value)
                result
            end

        end

        class VCARD30 < RFC2425
            version         '3.0'
            previous_version VCARD21
            def_component    VFormat::VCARD30
            register_as_default
        end
    end

end

# vim: shiftwidth=4 softtabstop=4 expandtab
