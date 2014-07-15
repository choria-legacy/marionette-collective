module MCollective
  module Security
    # Impliments a security system that encrypts payloads using AES and secures
    # the AES encrypted data using RSA public/private key encryption.
    #
    # The design goals of this plugin are:
    #
    # - Each actor - clients and servers - can have their own set of public and
    #   private keys
    # - All actors are uniquely and cryptographically identified
    # - Requests are encrypted using the clients private key and anyone that has
    #   the public key can see the request.  Thus an atacker may see the requests
    #   given access to network or machine due to the broadcast nature of mcollective
    # - The message time and TTL of messages are cryptographically secured making the
    #   ensuring messages can not be replayed with fake TTLs or times
    # - Replies are encrypted using the calling clients public key.  Thus no-one but
    #   the caller can view the contents of replies.
    # - Servers can all have their own RSA keys, or share one, or reuse keys created
    #   by other PKI using software like Puppet
    # - Requests from servers - like registration data - can be secured even to external
    #   eaves droppers depending on the level of configuration you are prepared to do
    # - Given a network where you can ensure third parties are not able to access the
    #   middleware public key distribution can happen automatically
    #
    # Configuration Options:
    # ======================
    #
    # Common Options:
    #
    #    # Enable this plugin
    #    securityprovider = aes_security
    #
    #    # Use YAML as serializer
    #    plugin.aes.serializer = yaml
    #
    #    # Send our public key with every request so servers can learn it
    #    plugin.aes.send_pubkey = 1
    #
    # Clients:
    #
    #    # The clients public and private keys
    #    plugin.aes.client_private = /home/user/.mcollective.d/user-private.pem
    #    plugin.aes.client_public = /home/user/.mcollective.d/user.pem
    #
    # Servers:
    #
    #    # Where to cache client keys or find manually distributed ones
    #    plugin.aes.client_cert_dir = /etc/mcollective/ssl/clients
    #
    #    # Cache public keys promiscuously from the network (this requires either a ca_cert to be set
    #      or insecure_learning to be enabled)
    #    plugin.aes.learn_pubkeys = 1
    #
    #    # Do not check if client certificate can be verified by a CA
    #    plugin.aes.insecure_learning = 1
    #
    #    # CA cert used to verify public keys when in learning mode
    #    plugin.aes.ca_cert = /etc/mcollective/ssl/ca.cert
    #
    #    # Log but accept messages that may have been tampered with
    #    plugin.aes.enforce_ttl = 0
    #
    #    # The servers public and private keys
    #    plugin.aes.server_private = /etc/mcollective/ssl/server-private.pem
    #    plugin.aes.server_public = /etc/mcollective/ssl/server-public.pem
    #
    class Aes_security<Base
      def decodemsg(msg)
        body = deserialize(msg.payload)

        should_process_msg?(msg, body[:requestid])
        # if we get a message that has a pubkey attached and we're set to learn
        # then add it to the client_cert_dir this should only happen on servers
        # since clients will get replies using their own pubkeys
        if Util.str_to_bool(@config.pluginconf.fetch("aes.learn_pubkeys", false)) && body.include?(:sslpubkey)
          certname = certname_from_callerid(body[:callerid])
          certfile = "#{client_cert_dir}/#{certname}.pem"
          if !File.exist?(certfile)
            if !Util.str_to_bool(@config.pluginconf.fetch("aes.insecure_learning", false))
              if !@config.pluginconf.fetch("aes.ca_cert", nil)
                raise "Cannot verify certificate for '#{certname}'. No CA certificate specified."
              end

              if !validate_certificate(body[:sslpubkey], certname)
                raise "Unable to validate certificate '#{certname}' against CA"
              end

              Log.debug("Verified certificate '#{certname}' against CA")
            else
              Log.warn("Insecure key learning is not a secure method of key distribution. Do NOT use this mode in sensitive environments.")
            end

            Log.debug("Caching client cert in #{certfile}")
            File.open(certfile, "w") {|f| f.print body[:sslpubkey]}
          else
            Log.debug("Not caching client cert. File #{certfile} already exists.")
          end
        end

        cryptdata = {:key => body[:sslkey], :data => body[:body]}

        if @initiated_by == :client
          body[:body] = deserialize(decrypt(cryptdata, nil))
        else
          certname = certname_from_callerid(body[:callerid])
          certfile = "#{client_cert_dir}/#{certname}.pem"
          # if aes.ca_cert is set every certificate is validated before we try and use it
          if @config.pluginconf.fetch("aes.ca_cert", nil) && !validate_certificate(File.read(certfile), certname)
            raise "Unable to validate certificate '#{certname}' against CA"
          end
          body[:body] = deserialize(decrypt(cryptdata, body[:callerid]))

          # If we got a hash it's possible that this is a message with secure
          # TTL and message time, attempt to decode that and transform into a
          # traditional message.
          #
          # If it's not a hash it might be a old style message like old discovery
          # ones that would just be a string so we allow that unaudited but only
          # if enforce_ttl is disabled.  This is primarly to allow a mixed old and
          # new plugin infrastructure to work
          if body[:body].is_a?(Hash)
            update_secure_property(body, :aes_ttl, :ttl, "TTL")
            update_secure_property(body, :aes_msgtime, :msgtime, "Message Time")

            body[:body] = body[:body][:aes_msg] if body[:body].include?(:aes_msg)
          else
            unless @config.pluginconf["aes.enforce_ttl"] == "0"
              raise "Message %s is in an unknown or older security protocol, ignoring" % [request_description(body)]
            end
          end
        end

        return body
      rescue MsgDoesNotMatchRequestID
        raise

      rescue OpenSSL::PKey::RSAError
        raise MsgDoesNotMatchRequestID, "Could not decrypt message using our key, possibly directed at another client"

      rescue Exception => e
        Log.warn("Could not decrypt message from client: #{e.class}: #{e}")
        raise SecurityValidationFailed, "Could not decrypt message"
      end

      # To avoid tampering we turn the origin body into a hash and copy some of the protocol keys
      # like :ttl and :msg_time into the hash before encrypting it.
      #
      # This function compares and updates the unencrypted ones based on the encrypted ones.  By
      # default it enforces matching and presense by raising exceptions, if aes.enforce_ttl is set
      # to 0 it will only log warnings about violations
      def update_secure_property(msg, secure_property, property, description)
        req = request_description(msg)

        unless @config.pluginconf["aes.enforce_ttl"] == "0"
          raise "Request #{req} does not have a secure #{description}" unless msg[:body].include?(secure_property)
          raise "Request #{req} #{description} does not match encrypted #{description} - possible tampering"  unless msg[:body][secure_property] == msg[property]
        else
          if msg[:body].include?(secure_property)
            Log.warn("Request #{req} #{description} does not match encrypted #{description} - possible tampering") unless msg[:body][secure_property] == msg[property]
          else
            Log.warn("Request #{req} does not have a secure #{description}") unless msg[:body].include?(secure_property)
          end
        end

        msg[property] = msg[:body][secure_property] if msg[:body].include?(secure_property)
        msg[:body].delete(secure_property)
      end

      # Encodes a reply
      def encodereply(sender, msg, requestid, requestcallerid)
        crypted = encrypt(serialize(msg), requestcallerid)

        req = create_reply(requestid, sender, crypted[:data])
        req[:sslkey] = crypted[:key]

        serialize(req)
      end

      # Encodes a request msg
      def encoderequest(sender, msg, requestid, filter, target_agent, target_collective, ttl=60)
        req = create_request(requestid, filter, nil, @initiated_by, target_agent, target_collective, ttl)

        # embed the ttl and msgtime in the crypted data later we will use these in
        # the decoding of a message to set the message ones from secure sources. this
        # is to ensure messages are not tampered with to facility replay attacks etc
        aes_msg = {:aes_msg => msg,
          :aes_ttl => ttl,
          :aes_msgtime => req[:msgtime]}

        crypted = encrypt(serialize(aes_msg), callerid)

        req[:body] = crypted[:data]
        req[:sslkey] = crypted[:key]

        if @config.pluginconf.include?("aes.send_pubkey") && @config.pluginconf["aes.send_pubkey"] == "1"
          if @initiated_by == :client
            req[:sslpubkey] = File.read(client_public_key)
          else
            req[:sslpubkey] = File.read(server_public_key)
          end
        end

        serialize(req)
      end

      # Serializes a message using the configured encoder
      def serialize(msg)
        serializer = @config.pluginconf["aes.serializer"] || "marshal"

        Log.debug("Serializing using #{serializer}")

        case serializer
        when "yaml"
          return YAML.dump(msg)
        else
          return Marshal.dump(msg)
        end
      end

      # De-Serializes a message using the configured encoder
      def deserialize(msg)
        serializer = @config.pluginconf["aes.serializer"] || "marshal"

        Log.debug("De-Serializing using #{serializer}")

        case serializer
        when "yaml"
          return YAML.load(msg)
        else
          return Marshal.load(msg)
        end
      end

      # sets the caller id to the md5 of the public key
      def callerid
        if @initiated_by == :client
          key = client_public_key
        else
          key = server_public_key
        end

        # First try and create a X509 certificate object. If that is possible,
        # we lift the callerid from the cert
        begin
          ssl_cert = OpenSSL::X509::Certificate.new(File.read(key))
          id = "cert=#{certname_from_certificate(ssl_cert)}"
        rescue
          # If the public key is not a certificate, use the file name as callerid
          id = "cert=#{File.basename(key).gsub(/\.pem$/, '')}"
        end

        return id
      end

      def encrypt(string, certid)
        if @initiated_by == :client
          @ssl ||= SSL.new(client_public_key, client_private_key)

          Log.debug("Encrypting message using private key")
          return @ssl.encrypt_with_private(string)
        else
          # when the server is initating requests like for registration
          # then the certid will be our callerid
          if certid == callerid
            Log.debug("Encrypting message using private key #{server_private_key}")

            ssl = SSL.new(server_public_key, server_private_key)
            return ssl.encrypt_with_private(string)
          else
            Log.debug("Encrypting message using public key for #{certid}")

            ssl = SSL.new(public_key_path_for_client(certid))
            return ssl.encrypt_with_public(string)
          end
        end
      end

      def decrypt(string, certid)
        if @initiated_by == :client
          @ssl ||= SSL.new(client_public_key, client_private_key)

          Log.debug("Decrypting message using private key")
          return @ssl.decrypt_with_private(string)
        else
          Log.debug("Decrypting message using public key for #{certid}")
          ssl = SSL.new(public_key_path_for_client(certid))
          return ssl.decrypt_with_public(string)
        end
      end

      def validate_certificate(client_cert, certid)
        cert_file = @config.pluginconf.fetch("aes.ca_cert", nil)

        begin
          ssl_cert = OpenSSL::X509::Certificate.new(client_cert)
        rescue OpenSSL::X509::CertificateError
          Log.warn("Received public key that is not a X509 certficate")
          return false
        end

        ssl_certname = certname_from_certificate(ssl_cert)

        if certid != ssl_certname
          Log.warn("certname '#{certid}' doesn't match certificate '#{ssl_certname}'")
          return false
        end

        Log.debug("Loading CA Cert for verification")
        ca_cert = OpenSSL::X509::Store.new
        ca_cert.add_file cert_file

        if ca_cert.verify(ssl_cert)
          Log.debug("Verified certificate '#{ssl_certname}' against CA")
        else
          # TODO add cert id
          Log.warn("Unable to validate certificate '#{ssl_certname}'' against CA")
          return false
        end
        return true
      end

      # On servers this will look in the aes.client_cert_dir for public
      # keys matching the clientid, clientid is expected to be in the format
      # set by callerid
      def public_key_path_for_client(clientid)
        raise "Unknown callerid format in '#{clientid}'" unless clientid.match(/^cert=(.+)$/)

        clientid = $1

        client_cert_dir + "/#{clientid}.pem"
      end

      # Figures out the client private key either from MCOLLECTIVE_AES_PRIVATE or the
      # plugin.aes.client_private config option
      def client_private_key
        return ENV["MCOLLECTIVE_AES_PRIVATE"] if ENV.include?("MCOLLECTIVE_AES_PRIVATE")

        raise("No plugin.aes.client_private configuration option specified") unless @config.pluginconf.include?("aes.client_private")

        return @config.pluginconf["aes.client_private"]
      end

      # Figures out the client public key either from MCOLLECTIVE_AES_PUBLIC or the
      # plugin.aes.client_public config option
      def client_public_key
        return ENV["MCOLLECTIVE_AES_PUBLIC"] if ENV.include?("MCOLLECTIVE_AES_PUBLIC")

        raise("No plugin.aes.client_public configuration option specified") unless @config.pluginconf.include?("aes.client_public")

        return @config.pluginconf["aes.client_public"]
      end

      # Figures out the server public key from the plugin.aes.server_public config option
      def server_public_key
        raise("No aes.server_public configuration option specified") unless @config.pluginconf.include?("aes.server_public")
        return @config.pluginconf["aes.server_public"]
      end

      # Figures out the server private key from the plugin.aes.server_private config option
      def server_private_key
        raise("No plugin.aes.server_private configuration option specified") unless @config.pluginconf.include?("aes.server_private")
        @config.pluginconf["aes.server_private"]
      end

      # Figures out where to get client public certs from the plugin.aes.client_cert_dir config option
      def client_cert_dir
        raise("No plugin.aes.client_cert_dir configuration option specified") unless @config.pluginconf.include?("aes.client_cert_dir")
        @config.pluginconf["aes.client_cert_dir"]
      end

      def request_description(msg)
        "%s from %s@%s" % [msg[:requestid], msg[:callerid], msg[:senderid]]
      end

      # Takes our cert=foo callerids and return the foo bit else nil
      def certname_from_callerid(id)
        if id =~ /^cert=([\w\.\-]+)/
          return $1
        else
          raise("Received a callerid in an unexpected format: '#{id}', ignoring")
        end
      end

      def certname_from_certificate(cert)
        id = cert.subject
        if id.to_s =~ /^\/CN=([\w\.\-]+)/
          return $1
        else
          raise("Received a callerid in an unexpected format in an SSL certificate: '#{id}', ignoring")
        end
      end
    end
  end
end
