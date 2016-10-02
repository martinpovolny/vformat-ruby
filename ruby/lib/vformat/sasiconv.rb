## - stupidni bug v iconvu, ktery se nevyrovna s rekodovanim vetsiho retezce
## - cachovani iconv objektu
if RUBY_VERSION =~ /^1\.8/
require 'iconv'

class Iconv
    MAX_STR_SIZE = 4096
    UTF8         = 'UTF-8'
    UTF8_SAFE    = 'UTF-8//IGNORE'

    @@from_utf8_cache = {}
    @@to_utf8_cache   = {}
    @@from_utf8_safe_cache = {}
    @@to_utf8_safe_cache   = {}

    ## +iconv+ musi byt ascii kompatibilni (ne UTF16, UCS4, ...)!
    #
    def self.safe_recode(iconv, str)
        if str.size > MAX_STR_SIZE
            t = nil
            res = []
            str.scan(/.*?(?:\n|$)/m) {|t| res << iconv.iconv(t)}
            res << iconv.iconv(nil)
            res.join
        else
            str = iconv.iconv(str)
            str << iconv.iconv(nil)
            str
        end
    end

    ## +enc+ musi byt ascii kompatibilni (ne UTF16, UCS4, ...)!
    #
    def self.to_utf8(enc, str)
        enc = enc.upcase
        return str.dup if enc == UTF8

        safe_recode(
            (@@to_utf8_cache[enc] ||= Iconv.new(UTF8, enc)),
            str
        )
    end

    ## +enc+ musi byt ascii kompatibilni (ne UTF16, UCS4, ...)!
    #
    def self.from_utf8(enc, str)
        enc = enc.upcase
        return str.dup if enc == UTF8

        safe_recode(
            (@@from_utf8_cache[enc] ||= Iconv.new(enc, UTF8)),
            str
        )
    end

    ## +enc+ musi byt ascii kompatibilni (ne UTF16, UCS4, ...)!
    #
    def self.to_utf8_safe(enc, str)
        enc = enc.upcase
        return str.dup if enc == UTF8

        safe_recode(
            (@@to_utf8_safe_cache[enc] ||= Iconv.new(UTF8_SAFE, enc)),
            str
        )
    end

    ## +enc+ musi byt ascii kompatibilni (ne UTF16, UCS4, ...)!
    #
    def self.from_utf8_safe(enc, str)
        enc = enc.upcase
        return str.dup if enc == UTF8

        safe_recode(
            (@@from_utf8_safe_cache[enc] ||= Iconv.new("#{enc}//IGNORE", UTF8)),
            str
        )
    end
end
end

module SasIconv
    if RUBY_VERSION =~ /^1\.8/
        def SasIconv::to_utf8(enc, s)
            Iconv.to_utf8(enc, s)
        end
        def SasIconv::to_utf8_safe(enc, s)
            Iconv.to_utf8_safe(enc, s)
        end
        def SasIconv::from_utf8(enc, s)
            Iconv.from_utf8(enc, s)
        end
        def SasIconv::from_utf8_safe(enc, s)
            Iconv.from_utf8_safe(enc, s)
        end
    else
        def SasIconv::to_utf8(enc, s)
            enc = Encoding::UTF_8 if enc == 'utf8'
            s.encode(Encoding::UTF_8, enc)
        end
        def SasIconv::to_utf8_safe(enc, s)
            # s.encode(to, from, ...) doesn't sanitize output if s.encoding is Encoding::ASCII_8BIT,
            # so set encoding temporarily to correct one and use s.encode(to, ...)
            s = s.dup
            enc = Encoding::UTF_8 if enc == 'utf8'
            s.force_encoding(enc)
            s.encode(Encoding::UTF_8, :invalid => :replace, :undef => :replace)
        end
        def SasIconv::from_utf8(enc, s)
            enc = Encoding::UTF_8 if enc == 'utf8'
            s.encode(enc, Encoding::UTF_8)
        end
        def SasIconv::from_utf8_safe(enc, s)
            enc = Encoding::UTF_8 if enc == 'utf8'
            s.encode(enc, :invalid => :replace, :undef => :replace)
        end
    end
end
