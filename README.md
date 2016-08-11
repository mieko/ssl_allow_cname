# ssl_allow_cname

`ssl_allow_cname` adds a parameter to Ruby's OpenSSL library: `allow_cname`.

This is for cases when you don't care about the host matching the CommonName or
a SubjectAlternateName of a certificate (e.g., you've got other security
measures), but surely don't want to turn off all peer verification.

Here's an example:

```ruby
# This actually works, using the Ruby redis client's SSL support:

redis = Redis.new(
  # Say the other side of this connection has a certificate you've signed, but
  # you don't care what VPS instance it ends on with an arbitrary IP.
  url: 'rediss://198.199.120.202/',  
  ssl_params: {
    # And you only trust yourself as a CA.
    ca_file: '/etc/ssl/metermd/metermd-ca.crt',

    # And the following cert has been signed by your CA, and the key's valid...
    cert: OpenSSL::X509::Certificate.new(File.read('/etc/ssl/metermd/redis-client.crt')),
    key: OpenSSL::PKey::RSA.new(File.read('/etc/ssl/metermd/redis-client.keydh')),

    # You just care that you've authorized this certificate for this purpose,
    # and rely on the security of your CA being legit.
    allow_cname: 'redis-server'
  }
)
```

Using the `allow_cname` option disables host verification, but specifying
`allow_cname: :match` will give you the same behavior as peer verification.
When you don't specify `allow_cname`, everything works the same as out-of-the-
box.

The value passed to `allow_cname` can take a few forms:

  * A `String`, which means the CommonName presented must exactly match what
    you've specified.
  * A `Regexp`, which will pass if it matches the CommonName of the peer
    certificate.
  * A `Proc`, which can accept either `(common_name)` or `(common_name, host)`
    argument lists.  Return `true` if you like it, false otherwise.
  * The symbol `:match`, which accepts anything OpenSSL would've considered
    valid.
  * An `Array` of any of the above, which **operates in an OR, not AND,
    fashion.**

For simplicity, and to make it easier to not get wrong, `ssl_allow_cname` does
not consider SubjectAlternateNames, just the first CommonName.  If you're
running your own CA, you'll be able to arrange this.
