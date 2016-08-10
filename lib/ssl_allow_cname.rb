require "ssl_allow_cname/version"
require 'openssl'

module SslAllowCname
  module MonkeyPatch

    module_function
    def verify_hostname(hostname, san)
      return @allow_cname ? verify_allow_cname(hostname, san)
                          : super
    end

    def verify_allow_cname(hostname, san)
      Array(@allow_cname).each do |test|
        case test
          when String
            return true if san == test
          when Regexp
            return true if test.match(san)
          when Proc
            result = (test.arity == 1) ? test.call(san)
                                       : test.call(san, hostname)
            return true if result
        end
      end
      return false
    end
  end
end

class OpenSSL::SSL::SSLContext
  attr_accessor :allow_cname
  prepend SslAllowCname::MonkeyPatch
end
