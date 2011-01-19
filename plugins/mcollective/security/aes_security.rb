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
        #    # Cache public keys promiscuously from the network
        #    plugin.aes.learn_pubkeys = 1
        #
        #    # The servers public and private keys
        #    plugin.aes.server_private = /etc/mcollective/ssl/server-private.pem
        #    plugin.aes.server_public = /etc/mcollective/ssl/server-public.pem
        #
        class Aes_security<Base
            def decodemsg(msg)
                body = deserialize(msg.payload)

                # if we get a message that has a pubkey attached and we're set to learn
                # then add it to the client_cert_dir this should only happen on servers
                # since clients will get replies using their own pubkeys
                if @config.pluginconf.include?("aes.learn_pubkeys") && @config.pluginconf["aes.learn_pubkeys"] == "1"
                    if body.include?(:sslpubkey)
                        if client_cert_dir
                            certname = certname_from_callerid(body[:callerid])
                            if certname
                                certfile = "#{client_cert_dir}/#{certname}.pem"
                                unless File.exist?(certfile)
                                    Log.debug("Caching client cert in #{certfile}")
                                    File.open(certfile, "w") {|f| f.print body[:sslpubkey]}
                                end
                            end
                        end
                    end
                end

                cryptdata = {:key => body[:sslkey], :data => body[:body]}

                if @initiated_by == :client
                    body[:body] = deserialize(decrypt(cryptdata, nil))
                else
                    body[:body] = deserialize(decrypt(cryptdata, body[:callerid]))
                end

                return body
            rescue OpenSSL::PKey::RSAError
                raise MsgDoesNotMatchRequestID, "Could not decrypt message using our key, possibly directed at another client"

            rescue Exception => e
                Log.warn("Could not decrypt message from client: #{e.class}: #{e}")
                raise SecurityValidationFailed, "Could not decrypt message"
            end

            # Encodes a reply
            def encodereply(sender, target, msg, requestid, requestcallerid)
                crypted = encrypt(serialize(msg), requestcallerid)

                Log.debug("Encoded a reply for request #{requestid} for #{requestcallerid}")

                req = {:senderid => @config.identity,
                       :requestid => requestid,
                       :senderagent => sender,
                       :msgtarget => target,
                       :msgtime => Time.now.to_i,
                       :sslkey => crypted[:key],
                       :body => crypted[:data]}

                serialize(req)
            end

            # Encodes a request msg
            def encoderequest(sender, target, msg, requestid, filter={})
                crypted = encrypt(serialize(msg), callerid)

                Log.debug("Encoding a request for '#{target}' with request id #{requestid}")

                req = {:senderid => @config.identity,
                       :requestid => requestid,
                       :msgtarget => target,
                       :msgtime => Time.now.to_i,
                       :body => crypted,
                       :filter => filter,
                       :callerid => callerid,
                       :sslkey => crypted[:key],
                       :body => crypted[:data]}

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
                    return "cert=#{File.basename(client_public_key).gsub(/\.pem$/, '')}"
                else
                    # servers need to set callerid as well, not usually needed but
                    # would be if you're doing registration or auditing or generating
                    # requests for some or other reason
                    return "cert=#{File.basename(server_public_key).gsub(/\.pem$/, '')}"
                end
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

            # Takes our cert=foo callerids and return the foo bit else nil
            def certname_from_callerid(id)
                if id =~ /^cert=(.+)/
                    return $1
                else
                    return nil
                end
            end
        end
    end
end
