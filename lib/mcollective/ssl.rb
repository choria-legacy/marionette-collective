require 'openssl'
require 'base64'
require 'digest/sha1'

module MCollective
  # A class that assists in encrypting and decrypting data using a
  # combination of RSA and AES
  #
  # Data will be AES encrypted for speed, the Key used in # the AES
  # stage will be encrypted using RSA
  #
  #   ssl = SSL.new(public_key, private_key, passphrase)
  #
  #   data = File.read("largefile.dat")
  #
  #   crypted_data = ssl.encrypt_with_private(data)
  #
  #   pp crypted_data
  #
  # This will result in a hash of data like:
  #
  #   crypted = {:key  => "crd4NHvG....=",
  #              :data => "XWXlqN+i...=="}
  #
  # The key and data will all be base 64 encoded already by default
  # you can pass a 2nd parameter as false to encrypt_with_private and
  # counterparts that will prevent the base 64 encoding
  #
  # You can pass the data hash into ssl.decrypt_with_public which
  # should return your original data
  #
  # There are matching methods for using a public key to encrypt
  # data to be decrypted using a private key
  class SSL
    attr_reader :public_key_file, :private_key_file, :ssl_cipher

    def initialize(pubkey=nil, privkey=nil, passphrase=nil, cipher=nil)
      @public_key_file = pubkey
      @private_key_file = privkey

      @public_key  = read_key(:public, pubkey)
      @private_key = read_key(:private, privkey, passphrase)

      @ssl_cipher = "aes-256-cbc"
      @ssl_cipher = Config.instance.ssl_cipher if Config.instance.ssl_cipher
      @ssl_cipher = cipher if cipher

      raise "The supplied cipher '#{@ssl_cipher}' is not supported" unless OpenSSL::Cipher.ciphers.include?(@ssl_cipher)
    end

    # Encrypts supplied data using AES and then encrypts using RSA
    # the key and IV
    #
    # Return a hash with everything optionally base 64 encoded
    def encrypt_with_public(plain_text, base64=true)
      crypted = aes_encrypt(plain_text)

      if base64
        key = base64_encode(rsa_encrypt_with_public(crypted[:key]))
        data = base64_encode(crypted[:data])
      else
        key = rsa_encrypt_with_public(crypted[:key])
        data = crypted[:data]
      end

      {:key => key, :data => data}
    end

    # Encrypts supplied data using AES and then encrypts using RSA
    # the key and IV
    #
    # Return a hash with everything optionally base 64 encoded
    def encrypt_with_private(plain_text, base64=true)
      crypted = aes_encrypt(plain_text)

      if base64
        key = base64_encode(rsa_encrypt_with_private(crypted[:key]))
        data = base64_encode(crypted[:data])
      else
        key = rsa_encrypt_with_private(crypted[:key])
        data = crypted[:data]
      end

      {:key => key, :data => data}
    end

    # Decrypts data, expects a hash as create with crypt_with_public
    def decrypt_with_private(crypted, base64=true)
      raise "Crypted data should include a key" unless crypted.include?(:key)
      raise "Crypted data should include data" unless crypted.include?(:data)

      if base64
        key = rsa_decrypt_with_private(base64_decode(crypted[:key]))
        aes_decrypt(key, base64_decode(crypted[:data]))
      else
        key = rsa_decrypt_with_private(crypted[:key])
        aes_decrypt(key, crypted[:data])
      end
    end

    # Decrypts data, expects a hash as create with crypt_with_private
    def decrypt_with_public(crypted, base64=true)
      raise "Crypted data should include a key" unless crypted.include?(:key)
      raise "Crypted data should include data" unless crypted.include?(:data)

      if base64
        key = rsa_decrypt_with_public(base64_decode(crypted[:key]))
        aes_decrypt(key, base64_decode(crypted[:data]))
      else
        key = rsa_decrypt_with_public(crypted[:key])
        aes_decrypt(key, crypted[:data])
      end
    end

    # Use the public key to RSA encrypt data
    def rsa_encrypt_with_public(plain_string)
      raise "No public key set" unless @public_key

      @public_key.public_encrypt(plain_string)
    end

    # Use the private key to RSA decrypt data
    def rsa_decrypt_with_private(crypt_string)
      raise "No private key set" unless @private_key

      @private_key.private_decrypt(crypt_string)
    end

    # Use the private key to RSA encrypt data
    def rsa_encrypt_with_private(plain_string)
      raise "No private key set" unless @private_key

      @private_key.private_encrypt(plain_string)
    end

    # Use the public key to RSA decrypt data
    def rsa_decrypt_with_public(crypt_string)
      raise "No public key set" unless @public_key

      @public_key.public_decrypt(crypt_string)
    end

    # encrypts a string, returns a hash of key, iv and data
    def aes_encrypt(plain_string)
      cipher = OpenSSL::Cipher::Cipher.new(ssl_cipher)
      cipher.encrypt

      key = cipher.random_key

      cipher.key = key
      cipher.pkcs5_keyivgen(key)
      encrypted_data = cipher.update(plain_string) + cipher.final

      {:key => key, :data => encrypted_data}
    end

    # decrypts a string given key, iv and data
    def aes_decrypt(key, crypt_string)
      cipher = OpenSSL::Cipher::Cipher.new(ssl_cipher)

      cipher.decrypt
      cipher.key = key
      cipher.pkcs5_keyivgen(key)
      decrypted_data = cipher.update(crypt_string) + cipher.final
    end

    # Signs a string using the private key
    def sign(string, base64=false)
      sig = @private_key.sign(OpenSSL::Digest::SHA1.new, string)

      base64 ? base64_encode(sig) : sig
    end

    # Using the public key verifies that a string was signed using the private key
    def verify_signature(signature, string, base64=false)
      signature = base64_decode(signature) if base64

      @public_key.verify(OpenSSL::Digest::SHA1.new, signature, string)
    end

    # base 64 encode a string
    def base64_encode(string)
      SSL.base64_encode(string)
    end

    def self.base64_encode(string)
      Base64.encode64(string)
    end

    # base 64 decode a string
    def base64_decode(string)
      SSL.base64_decode(string)
    end

    def self.base64_decode(string)
      # The Base 64 character set is A-Z a-z 0-9 + / =
      # Also allow for whitespace, but raise if we get anything else
      if string !~ /^[A-Za-z0-9+\/=\s]+$/
        raise ArgumentError, 'invalid base64'
      end
      Base64.decode64(string)
    end

    def md5(string)
      SSL.md5(string)
    end

    def self.md5(string)
      Digest::MD5.hexdigest(string)
    end

    # Creates a RFC 4122 version 5 UUID. If string is supplied it will produce repeatable
    # UUIDs for that string else a random 128bit string will be used from OpenSSL::BN
    #
    # Code used with permission from:
    #    https://github.com/kwilczynski/puppet-functions/blob/master/lib/puppet/parser/functions/uuid.rb
    #
    def self.uuid(string=nil)
      string ||= OpenSSL::Random.random_bytes(16).unpack('H*').shift

      uuid_name_space_dns = [0x6b, 0xa7, 0xb8, 0x10, 0x9d, 0xad, 0x11, 0xd1, 0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8].map {|b| b.chr}.join

      sha1 = Digest::SHA1.new
      sha1.update(uuid_name_space_dns)
      sha1.update(string)

      # first 16 bytes..
      bytes = sha1.digest[0, 16].bytes.to_a

      # version 5 adjustments
      bytes[6] &= 0x0f
      bytes[6] |= 0x50

      # variant is DCE 1.1
      bytes[8] &= 0x3f
      bytes[8] |= 0x80

      bytes = [4, 2, 2, 2, 6].collect do |i|
        bytes.slice!(0, i).pack('C*').unpack('H*')
      end

      bytes.join('-')
    end

    # Reads either a :public or :private key from disk, uses an
    # optional passphrase to read the private key
    def read_key(type, key=nil, passphrase=nil)
      return key if key.nil?

      raise "Could not find key #{key}" unless File.exist?(key)
      raise "#{type} key file '#{key}' is empty" if File.zero?(key)

      if type == :public
        begin
          key = OpenSSL::PKey::RSA.new(File.read(key))
        rescue OpenSSL::PKey::RSAError
          key = OpenSSL::X509::Certificate.new(File.read(key)).public_key
        end

        # Ruby < 1.9.3 had a bug where it does not correctly clear the
        # queue of errors while reading a key.  It tries various ways
        # to read the key and each failing attempt pushes an error onto
        # the queue.  With pubkeys only the 3rd attempt pass leaving 2
        # stale errors on the error queue.
        #
        # In 1.9.3 they fixed this by simply discarding the errors after
        # every attempt.  So we simulate this fix here for older rubies
        # as without it we get SSL_read errors from the Stomp+TLS sessions
        #
        # We do this only on 1.8 relying on 1.9.3 to do the right thing
        # and we do not support 1.9 less than 1.9.3
        #
        # See  http://bugs.ruby-lang.org/issues/4550
        OpenSSL.errors if Util.ruby_version =~ /^1.8/

        return key
      elsif type == :private
        return OpenSSL::PKey::RSA.new(File.read(key), passphrase)
      else
        raise "Can only load :public or :private keys"
      end
    end

  end
end
