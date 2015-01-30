require 'base64'
require 'openssl'

module MCollective
  module Security
    # Impliments a public/private key based message validation system using SSL
    # public and private keys.
    #
    # The design goal of the plugin is two fold:
    #
    # - give different security credentials to clients and servers to avoid
    #   a compromised server from sending new client requests.
    # - create a token that uniquely identify the client - based on the filename
    #   of the public key
    #
    # To setup you need to create a SSL key pair that is shared by all nodes.
    #
    #   openssl genrsa -out mcserver-private.pem 1024
    #   openssl rsa -in mcserver-private.pem -out mcserver-public.pem -outform PEM -pubout
    #
    # Distribute the private and public file to /etc/mcollective/ssl on all the nodes.
    # Distribute the public file to /etc/mcollective/ssl everywhere the client code runs.
    #
    # Now you should create a key pair for every one of your clients, here we create one
    # for user john - you could also if you are less concerned with client id create one
    # pair and share it with all clients:
    #
    #   openssl genrsa -out john-private.pem 1024
    #   openssl rsa -in john-private.pem -out john-public.pem -outform PEM -pubout
    #
    # Each user has a unique userid, this is based on the name of the public key.
    # In this example case the userid would be 'john-public'.
    #
    # Store these somewhere like:
    #
    #     /home/john/.mc/john-private.pem
    #     /home/john/.mc/john-public.pem
    #
    # Every users public key needs to be distributed to all the nodes, save the john one
    # in a file called:
    #
    #   /etc/mcollective/ssl/clients/john-public.pem
    #
    # If you wish to use registration or auditing that sends connections over MC to a
    # central host you will need also put the server-public.pem in the clients directory.
    #
    # You should be aware if you do add the node public key to the clients dir you will in
    # effect be weakening your overall security.  You should consider doing this only if
    # you also set up an Authorization method that limits the requests the nodes can make.
    #
    # client.cfg:
    #
    #   securityprovider = ssl
    #   plugin.ssl_server_public = /etc/mcollective/ssl/server-public.pem
    #   plugin.ssl_client_private = /home/john/.mc/john-private.pem
    #   plugin.ssl_client_public = /home/john/.mc/john-public.pem
    #
    # If you have many clients per machine and dont want to configure the main config file
    # with the public/private keys you can set the following environment variables:
    #
    #   export MCOLLECTIVE_SSL_PRIVATE=/home/john/.mc/john-private.pem
    #   export MCOLLECTIVE_SSL_PUBLIC=/home/john/.mc/john-public.pem
    #
    # server.cfg:
    #
    #   securityprovider = ssl
    #   plugin.ssl_server_private = /etc/mcollective/ssl/server-private.pem
    #   plugin.ssl_server_public = /etc/mcollective/ssl/server-public.pem
    #   plugin.ssl_client_cert_dir = /etc/mcollective/etc/ssl/clients/
    #
    #   # Log but accept messages that may have been tampered with
    #   plugin.ssl.enforce_ttl = 0
    #
    # Serialization can be configured to use either Marshal or YAML, data types
    # in and out of mcollective will be preserved from client to server and reverse
    #
    # You can configure YAML serialization:
    #
    #    plugins.ssl_serializer = yaml
    #
    # else the default is Marshal.  Use YAML if you wish to write a client using
    # a language other than Ruby that doesn't support Marshal.
    #
    # Validation is as default and is provided by MCollective::Security::Base
    #
    # Initial code was contributed by Vladimir Vuksan and modified by R.I.Pienaar
    class Ssl < Base
      # Decodes a message by unserializing all the bits etc, it also validates
      # it as valid using the psk etc
      def decodemsg(msg)
        body = deserialize(msg.payload)

        should_process_msg?(msg, body[:requestid])

        if validrequest?(body)
          body[:body] = deserialize(body[:body])

          unless @initiated_by == :client
            if body[:body].is_a?(Hash)
              update_secure_property(body, :ssl_ttl, :ttl, "TTL")
              update_secure_property(body, :ssl_msgtime, :msgtime, "Message Time")

              body[:body] = body[:body][:ssl_msg] if body[:body].include?(:ssl_msg)
            else
              unless @config.pluginconf["ssl.enforce_ttl"] == nil
                raise "Message %s is in an unknown or older security protocol, ignoring" % [request_description(body)]
              end
            end
          end

          return body
        else
          nil
        end
      end

      # To avoid tampering we turn the origin body into a hash and copy some of the protocol keys
      # like :ttl and :msg_time into the hash before hashing it.
      #
      # This function compares and updates the unhashed ones based on the hashed ones.  By
      # default it enforces matching and presense by raising exceptions, if ssl.enforce_ttl is set
      # to 0 it will only log warnings about violations
      def update_secure_property(msg, secure_property, property, description)
        req = request_description(msg)

        unless @config.pluginconf["ssl.enforce_ttl"] == "0"
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
      def encodereply(sender, msg, requestid, requestcallerid=nil)
        serialized  = serialize(msg)
        digest = makehash(serialized)


        req = create_reply(requestid, sender, serialized)
        req[:hash] = digest

        serialize(req)
      end

      # Encodes a request msg
      def encoderequest(sender, msg, requestid, filter, target_agent, target_collective, ttl=60)
        req = create_request(requestid, filter, "", @initiated_by, target_agent, target_collective, ttl)

        ssl_msg = {:ssl_msg => msg,
                   :ssl_ttl => ttl,
                   :ssl_msgtime => req[:msgtime]}

        serialized = serialize(ssl_msg)
        digest = makehash(serialized)

        req[:hash] = digest
        req[:body] = serialized

        serialize(req)
      end

      # Checks the SSL signature in the request body
      def validrequest?(req)
        message = req[:body]
        signature = req[:hash]

        Log.debug("Validating request from #{req[:callerid]}")

        if verify(public_key_file(req[:callerid]), signature, message.to_s)
          @stats.validated
          return true
        else
          @stats.unvalidated
          raise(SecurityValidationFailed, "Received an invalid signature in message")
        end
      end


      # sets the caller id to the md5 of the public key
      def callerid
        if @initiated_by == :client
          id = "cert=#{File.basename(client_public_key).gsub(/\.pem$/, '')}"
          raise "Invalid callerid generated from client public key" unless valid_callerid?(id)
        else
          # servers need to set callerid as well, not usually needed but
          # would be if you're doing registration or auditing or generating
          # requests for some or other reason
          id = "cert=#{File.basename(server_public_key).gsub(/\.pem$/, '')}"
          raise "Invalid callerid generated from server public key" unless valid_callerid?(id)
        end

        return id
      end

      private
      # Serializes a message using the configured encoder
      def serialize(msg)
        serializer = @config.pluginconf["ssl_serializer"] || "marshal"

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
        serializer = @config.pluginconf["ssl_serializer"] || "marshal"

        Log.debug("De-Serializing using #{serializer}")

        case serializer
        when "yaml"
          return YAML.load(msg)
        else
          return Marshal.load(msg)
        end
      end

      # Figures out where to get our private key
      def private_key_file
        if ENV.include?("MCOLLECTIVE_SSL_PRIVATE")
          return ENV["MCOLLECTIVE_SSL_PRIVATE"]
        else
          if @initiated_by == :node
            return server_private_key
          else
            return client_private_key
          end
        end
      end

      # Figures out the public key to use
      #
      # If the node is asking do it based on caller id
      # If the client is asking just get the node public key
      def public_key_file(callerid = nil)
        if @initiated_by == :client
          return server_public_key
        else
          if callerid =~ /cert=([\w\.\-]+)/
            cid = $1

            if File.exist?("#{client_cert_dir}/#{cid}.pem")
              return "#{client_cert_dir}/#{cid}.pem"
            else
              raise("Could not find a public key for #{cid} in #{client_cert_dir}/#{cid}.pem")
            end
          else
            raise("Caller id is not in the expected format")
          end
        end
      end

      # Figures out the client private key either from MCOLLECTIVE_SSL_PRIVATE or the
      # plugin.ssl_client_private config option
      def client_private_key
        return ENV["MCOLLECTIVE_SSL_PRIVATE"] if ENV.include?("MCOLLECTIVE_SSL_PRIVATE")

        raise("No plugin.ssl_client_private configuration option specified") unless @config.pluginconf.include?("ssl_client_private")

        return @config.pluginconf["ssl_client_private"]
      end

      # Figures out the client public key either from MCOLLECTIVE_SSL_PUBLIC or the
      # plugin.ssl_client_public config option
      def client_public_key
        return ENV["MCOLLECTIVE_SSL_PUBLIC"] if ENV.include?("MCOLLECTIVE_SSL_PUBLIC")

        raise("No plugin.ssl_client_public configuration option specified") unless @config.pluginconf.include?("ssl_client_public")

        return @config.pluginconf["ssl_client_public"]
      end

      # Figures out the server private key from the plugin.ssl_server_private config option
      def server_private_key
        raise("No plugin.ssl_server_private configuration option specified") unless @config.pluginconf.include?("ssl_server_private")
        @config.pluginconf["ssl_server_private"]
      end

      # Figures out the server public key from the plugin.ssl_server_public config option
      def server_public_key
        raise("No ssl_server_public configuration option specified") unless @config.pluginconf.include?("ssl_server_public")
        return @config.pluginconf["ssl_server_public"]
      end

      # Figures out where to get client public certs from the plugin.ssl_client_cert_dir config option
      def client_cert_dir
        raise("No plugin.ssl_client_cert_dir configuration option specified") unless @config.pluginconf.include?("ssl_client_cert_dir")
        @config.pluginconf["ssl_client_cert_dir"]
      end

      # Retrieves the value of plugin.psk and builds a hash with it and the passed body
      def makehash(body)
        Log.debug("Creating message hash using #{private_key_file}")

        sign(private_key_file, body.to_s)
      end

      # Code adapted from http://github.com/adamcooke/basicssl
      # signs a message
      def sign(key, string)
        SSL.new(nil, key).sign(string, true)
      end

      # verifies a signature
      def verify(key, signature, string)
        SSL.new(key).verify_signature(signature, string, true)
      end

      def request_description(msg)
        "%s from %s@%s" % [msg[:requestid], msg[:callerid], msg[:senderid]]
      end
    end
  end
end
