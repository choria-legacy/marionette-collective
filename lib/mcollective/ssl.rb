require 'openssl'
require 'base64'

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
    # The key and data will all be base 64 encoded already
    #
    # You can pass the data hash into ssl.decrypt_with_public which
    # should return your original data
    #
    # There are matching methods for using a public key to encrypt
    # data to be decrypted using a private key
    class SSL
        attr_reader :public_key_file, :private_key_file

        def initialize(pubkey=nil, privkey=nil, passphrase=nil)
            @public_key_file = pubkey
            @private_key_file = privkey

            @public_key  = read_key(:public, pubkey)
            @private_key = read_key(:private, privkey, passphrase)
        end

        # Encrypts supplied data using AES and then encrypts using RSA
        # the key and IV
        #
        # Return a hash with everything base 64 encoded
        def encrypt_with_public(plain_text)
            crypted = aes_encrypt(plain_text)

            encoded_key = base64_encode(rsa_encrypt_with_public(crypted[:key]))
            encoded_data = base64_encode(crypted[:data])

            {:key => encoded_key, :data => encoded_data}
        end

        # Encrypts supplied data using AES and then encrypts using RSA
        # the key and IV
        #
        # Return a hash with everything base 64 encoded
        def encrypt_with_private(plain_text)
            crypted = aes_encrypt(plain_text)

            encoded_key = base64_encode(rsa_encrypt_with_private(crypted[:key]))
            encoded_data = base64_encode(crypted[:data])

            {:key => encoded_key, :data => encoded_data}
        end

        # Decrypts data, expects a hash as create with crypt_with_public
        def decrypt_with_private(crypted)
            raise "Crypted data should include a key" unless crypted.include?(:key)
            raise "Crypted data should include data" unless crypted.include?(:data)

            key = rsa_decrypt_with_private(base64_decode(crypted[:key]))

            aes_decrypt(key, base64_decode(crypted[:data]))
        end

        # Decrypts data, expects a hash as create with crypt_with_private
        def decrypt_with_public(crypted)
            raise "Crypted data should include a key" unless crypted.include?(:key)
            raise "Crypted data should include data" unless crypted.include?(:data)

            key = rsa_decrypt_with_public(base64_decode(crypted[:key]))

            aes_decrypt(key, base64_decode(crypted[:data]))
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
            cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
            cipher.encrypt

            key = cipher.random_key

            cipher.key = key
            cipher.pkcs5_keyivgen(key)
            encrypted_data = cipher.update(plain_string) + cipher.final

            {:key => key, :data => encrypted_data}
        end

        # decrypts a string given key, iv and data
        def aes_decrypt(key, crypt_string)
            cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')

            cipher.decrypt
            cipher.key = key
            cipher.pkcs5_keyivgen(key)
            decrypted_data = cipher.update(crypt_string) + cipher.final
        end

        # base 64 encode a string
        def base64_encode(string)
            Base64.encode64(string).chomp
        end

        # base 64 decode a string
        def base64_decode(string)
            Base64.decode64(string)
        end

        # Reads either a :public or :private key from disk, uses an
        # optional passphrase to read the private key
        def read_key(type, key=nil, passphrase=nil)
            return key if key.nil?

            raise "Could not find key #{key}" unless File.exist?(key)

            if type == :public
                return OpenSSL::PKey::RSA.new(File.read(key))
            elsif type == :private
                return OpenSSL::PKey::RSA.new(File.read(key), passphrase)
            else
                raise "Can only load :public or :private keys"
            end
        end

    end
end
