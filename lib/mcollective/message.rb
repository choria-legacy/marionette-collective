module MCollective
    # container for a message, its headers, agent, collective and other meta data
    class Message
        attr_reader :message, :request, :validated, :msgtime, :payload, :type
        attr_accessor :headers, :agent, :collective, :filter
        attr_accessor :requestid, :discovered_hosts, :options, :ttl

        VALIDTYPES = [:message, :request, :direct_request, :reply]

        # payload              - the message body without headers etc, just the text
        # message              - the original message received from the middleware
        # options[:base64]     - if the body base64 encoded?
        # options[:agent]      - the agent the message is for/from
        # options[:collective] - the collective its for/from
        # options[:headers]    - the message headers
        # options[:type]       - an indicator about the type of message, :message, :request, :direct_request or :reply
        # options[:request]    - if this is a reply this should old the message we are replying to
        # options[:filter]     - for requests, the filter to encode into the message
        # options[:options]    - the normal client options hash
        # options[:ttl]        - the maximum amount of seconds this message can be valid for
        def initialize(payload, message, options = {})
            options = {:base64 => false,
                       :agent => nil,
                       :headers => {},
                       :type => :message,
                       :request => nil,
                       :filter => Util.empty_filter,
                       :options => {},
                       :ttl => 60,
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

            @ttl = @options[:ttl] || Config.instance.ttl
            @msgtime = 0

            @validated = false

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

        # Sets the message type to one of the known types.  In the case of :direct_request
        # the list of hosts to communicate with should have been set with #discovered_hosts
        # else an exception will be raised.  This is for extra security, we never accidentally
        # want to send a direct request without a list of hosts or something weird like that
        # as it might result in a filterless broadcast being sent.
        #
        # Additionally you simply cannot set :direct_request if direct_addressing was not enabled
        # this is to force a workflow that doesnt not yield in a mistake when someone might assume
        # direct_addressing is enabled when its not.
        def type=(type)
            if type == :direct_request
                raise "Direct requests is not enabled using the direct_addressing config option" unless Config.instance.direct_addressing

                unless @discovered_hosts && !@discovered_hosts.empty?
                    raise "Can only set type to :direct_request if discovered_hosts have been set"
                end
            end

            raise "Unknown message type #{type}" unless VALIDTYPES.include?(type)

            @type = type
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
                when :request, :direct_request
                    @requestid = create_reqid
                    @payload = PluginManager["security_plugin"].encoderequest(Config.instance.identity, payload, requestid, filter, agent, collective, ttl)
                else
                    raise "Cannot encode #{type} messages"
            end
        end

        def decode!
            raise "Cannot decode message type #{type}" unless [:request, :reply].include?(type)

            @payload = PluginManager["security_plugin"].decodemsg(self)

            [:collective, :agent, :filter, :requestid, :ttl, :msgtime].each do |prop|
                instance_variable_set("@#{prop}", payload[prop]) if payload.include?(prop)
            end
        end

        # Perform validation against the message by checking filters and ttl
        def validate
            raise "Can only validate request messages" unless type == :request

            msg_age = Time.now.utc.to_i - msgtime

            if msg_age > ttl
                cid = ""
                cid += payload[:callerid] + "@" if payload.include?(:callerid)
                cid += payload[:senderid]

                if msg_age > ttl
                    PluginManager["global_stats"].ttlexpired

                    raise(MsgTTLExpired, "Message #{requestid} from #{cid} created at #{msgtime} is #{msg_age} seconds old, TTL is #{ttl}")
                end
            end

            raise(NotTargettedAtUs, "Received message is not targetted to us") unless PluginManager["security_plugin"].validate_filter?(payload[:filter])

            @validated = true
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
