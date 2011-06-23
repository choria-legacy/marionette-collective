module MCollective
    # container for a message, its headers, agent, collective and other meta data
    class Message
        attr_reader :payload, :message, :request
        attr_accessor :headers, :agent, :collective, :type, :filter
        attr_accessor :requestid, :discovered_hosts, :options

        # payload              - the message body without headers etc, just the text
        # message              - the original message received from the middleware
        # options[:base64]     - if the body base64 encoded?
        # options[:agent]      - the agent the message is for/from
        # options[:collective] - the collective its for/from
        # options[:headers]    - the message headers
        # options[:type]       - an indicator about the type of message, :message, :request or :reply
        # options[:request]    - if this is a reply this should old the message we are replying to
        # options[:filter]     - for requests, the filter to encode into the message
        # options[:options]    - the normal client options hash
        def initialize(payload, message, options = {})
            options = {:base64 => false,
                       :agent => nil,
                       :headers => {},
                       :type => :message,
                       :request => nil,
                       :filter => Util.empty_filter,
                       :options => false,
                       :collective => nil}.merge(options)

            @payload = payload
            @message = message
            @requestid = nil
            @discovered_hosts = nil

            @type = options[:type]
            @headers = options[:headers]
            @base64 = options[:base64]
            @filter = options[:filter]
            @options = options[:options]

            if options[:request]
                @request = options[:request]
                @agent = request.agent
                @collective = request.collective
                @type = :reply
            else
                @agent = options[:agent]
                @collective = options[:collective]
            end

            base64_decode!
        end

        def base64_decode!
            return unless @base64

            @body = SSL.base64_decode(@body)
            @base64 = false
        end

        def base64_encode!
            return if @base64

            @body = SSL.base64_encode(@body)
            @base64 = true
        end

        def base64?
            @base64
        end

        def encode!
            case type
                when :reply
                    raise "Cannot encode a reply message if no request has been associated with it" unless request

                    @requestid = request.payload[:requestid]
                    @payload = PluginManager["security_plugin"].encodereply(agent, payload, requestid, request.payload[:callerid])
                when :request
                    @requestid = create_reqid
                    @payload = PluginManager["security_plugin"].encoderequest(Config.instance.identity, payload, requestid, filter, agent, collective)
                else
                    raise "Cannot encode #{type} messages"
            end
        end

        def decode!
            raise "Cannot decode message type #{type}" unless [:request, :reply].include?(type)

            @payload = PluginManager["security_plugin"].decodemsg(self)

            @collective = payload[:collective] if payload.include?(:collective)
            @agent = payload[:agent] if payload.include?(:agent)
            @filter = payload[:filter] if payload.include?(:filter)
            @requestid = payload[:requestid] if payload.include?(:requestid)
        end

        # Validates the message is targeted at us using the security plugin
        def validate
            raise "Can only validate request messages" unless type == :request

            raise(NotTargettedAtUs, "Received message is not targetted to us") unless PluginManager["security_plugin"].validate_filter?(payload[:filter])
        end

        # publish a reply message by creating a target name and sending it
        def publish
            Timeout.timeout(2) do
                # If we've been specificaly told about hosts that were discovered
                # use that information to do P2P calls if appropriate else just
                # send it as is.
                if @discovered_hosts && Config.instance.direct_addressing
                    if @discovered_hosts.size <= Config.instance.direct_addressing_threshold
                        @type = :direct_request
                        Log.debug("Handling #{requestid} as a direct request")
                    end

                    PluginManager["connector_plugin"].publish(self)
                else
                    PluginManager["connector_plugin"].publish(self)
                end
            end
        end

        def create_reqid
            Digest::MD5.hexdigest("#{Config.instance.identity}-#{Time.now.to_f}-#{agent}-#{collective}")
        end
    end
end
# vi:tabstop=4:expandtab:ai
