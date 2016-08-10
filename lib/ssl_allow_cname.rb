require "ssl_allow_cname/version"
require 'openssl'

module SslAllowCname
  module SSLContext
    attr_accessor :allow_cname
  end

  module SSLSocket
    def post_connection_check(hostname)
      return super if context.allow_cname.nil?

      cname = peer_cert.subject.to_a.map do |oid, value|
        oid == 'CN' ? value : nil
      end.compact.first

      passed = Array(context.allow_cname).any? do |test|
        case test
        when String, Regexp
          test === cname
        when Proc
          (test.arity == 1) ? test.call(cname)
                            : test.call(cname, hostname)
        when :match
          begin
            super
            true
          rescue SSLError
            false
          end
        end
      end

      unless passed
        fail OpenSSL::SSL::SSLError, "Peer certificate did not match any " +
                                     "predicate in :allow_cname.  Use :match " +
                                     "to get normal CommonName/Host validation"
      end
    end
  end
end

OpenSSL::SSL::SSLContext.prepend(SslAllowCname::SSLContext)
OpenSSL::SSL::SSLSocket.prepend(SslAllowCname::SSLSocket)
