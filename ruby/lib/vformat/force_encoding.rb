
class String
  if RUBY_VERSION =~ /^1\.8/
    def enc_is_b64?
        self =~ /([\x00-\x08]|[\x0a-\x1f])/n
    end
    def raw_is_b64?
        self =~ /([\x00-\x08]|[\x0e-\x1f])/n
    end
    def raw_is_qp?
        self =~ /([\r\n]|[^\x00-\x7f])/n
    end
    def force_encoding_vformat(enc)
        self
    end
    def self.to_utf8(str, charset)
        @iconv_charset ||= nil

        unless @iconv_charset == charset
            @iconv_charset = charset
        end
        SasIconv.to_utf8(@iconv_charset, str)
    end
  else
    def enc_is_b64?
        self =~ /([\x00-\x08]|[\x0a-\x1f])/u
    end
    def raw_is_b64?
        self =~ /([\x00-\x08]|[\x0e-\x1f])/u
    end
    def raw_is_qp?
        self =~ /([\r\n]|[^\x00-\x7f])/u
    end
    def force_encoding_vformat(enc)
        force_encoding(enc)
    end
    def self.to_utf8(str, charset)
        str.dup.to_s.force_encoding(charset).encode(Encoding::UTF_8)
    end
  end
end

