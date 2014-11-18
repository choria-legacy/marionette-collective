module MCollective
  # Helpers for writing clients that can talk to agents, do discovery and so forth
  class Client
    attr_accessor :options, :stats, :discoverer, :connection_timeout

    def initialize(options)
      @config = Config.instance
      @options = nil

      if options.is_a?(String)
        # String is the path to a config file
        @config.loadconfig(options) unless @config.configured
      elsif options.is_a?(Hash)
        @config.loadconfig(options[:config]) unless @config.configured
        @options = options
        @connection_timeout = options[:connection_timeout]
      else
        raise "Invalid parameter passed to Client constructor. Valid types are Hash or String"
      end

      @connection_timeout ||= @config.connection_timeout

      @connection = PluginManager["connector_plugin"]
      @security = PluginManager["security_plugin"]

      @security.initiated_by = :client
      @subscriptions = {}

      @discoverer = Discovery.new(self)

      # Time box the connection if a timeout has been specified
      # connection_timeout defaults to nil which means it will try forever if
      # not specified
      begin
        Timeout::timeout(@connection_timeout, ClientTimeoutError) do
          @connection.connect
        end
      rescue ClientTimeoutError => e
        Log.error("Timeout occured while trying to connect to middleware")
        raise e
      end
    end

    @@request_sequence = 0
    def self.request_sequence
      @@request_sequence
    end

    # Returns the configured main collective if no
    # specific collective is specified as options
    def collective
      if @options[:collective].nil?
        @config.main_collective
      else
        @options[:collective]
      end
    end

    # Disconnects cleanly from the middleware
    def disconnect
      Log.debug("Disconnecting from the middleware")
      @connection.disconnect
    end

    # Sends a request and returns the generated request id, doesn't wait for
    # responses and doesn't execute any passed in code blocks for responses
    def sendreq(msg, agent, filter = {})
      request = createreq(msg, agent, filter)

      Log.debug("Sending request #{request.requestid} to the #{request.agent} agent with ttl #{request.ttl} in collective #{request.collective}")

      request.publish
      request.requestid
    end

    def createreq(msg, agent, filter ={})
      if msg.is_a?(Message)
        request = msg
        agent = request.agent
      else
        ttl = @options[:ttl] || @config.ttl
        request = Message.new(msg, nil, {:agent => agent, :type => :request, :collective => collective, :filter => filter, :ttl => ttl})
        request.reply_to = @options[:reply_to] if @options[:reply_to]
      end

      @@request_sequence += 1

      request.encode!
      subscribe(agent, :reply) unless request.reply_to
      request
    end

    def subscribe(agent, type)
      unless @subscriptions.include?(agent)
        subscription = Util.make_subscriptions(agent, type, collective)
        Log.debug("Subscribing to #{type} target for agent #{agent}")

        Util.subscribe(subscription)
        @subscriptions[agent] = 1
      end
    end

    def unsubscribe(agent, type)
      if @subscriptions.include?(agent)
        subscription = Util.make_subscriptions(agent, type, collective)
        Log.debug("Unsubscribing #{type} target for #{agent}")

        Util.unsubscribe(subscription)
        @subscriptions.delete(agent)
      end
    end
    # Blocking call that waits for ever for a message to arrive.
    #
    # If you give it a requestid this means you've previously send a request
    # with that ID and now you just want replies that matches that id, in that
    # case the current connection will just ignore all messages not directed at it
    # and keep waiting for more till it finds a matching message.
    def receive(requestid = nil)
      reply = nil

      begin
        reply = @connection.receive
        reply.type = :reply
        reply.expected_msgid = requestid

        reply.decode!

        unless reply.requestid == requestid
          raise(MsgDoesNotMatchRequestID, "Message reqid #{reply.requestid} does not match our reqid #{requestid}")
        end

        Log.debug("Received reply to #{reply.requestid} from #{reply.payload[:senderid]}")
      rescue SecurityValidationFailed => e
        Log.warn("Ignoring a message that did not pass security validations")
        retry
      rescue MsgDoesNotMatchRequestID => e
        Log.debug("Ignoring a message for some other client : #{e.message}")
        retry
      end

      reply
    end

    # Performs a discovery of nodes matching the filter passed
    # returns an array of nodes
    #
    # An integer limit can be supplied this will have the effect
    # of the discovery being cancelled soon as it reached the
    # requested limit of hosts
    def discover(filter, timeout, limit=0)
      @discoverer.discover(filter.merge({'collective' => collective}), timeout, limit)
    end

    # Send a request, performs the passed block for each response
    #
    # times = req("status", "mcollectived", options, client) {|resp|
    #   pp resp
    # }
    #
    # It returns a hash of times and timeouts for discovery and total run is taken from the options
    # hash which in turn is generally built using MCollective::Optionparser
    def req(body, agent=nil, options=false, waitfor=0, &block)
      if body.is_a?(Message)
        agent = body.agent
        waitfor = body.discovered_hosts.size || 0
        @options = body.options
      end

      @options = options if options
      threaded = @options[:threaded]
      timeout = @discoverer.discovery_timeout(@options[:timeout], @options[:filter])
      request = createreq(body, agent, @options[:filter])
      publish_timeout = @options[:publish_timeout]
      stat = {:starttime => Time.now.to_f, :discoverytime => 0, :blocktime => 0, :totaltime => 0}
      STDOUT.sync = true
      hosts_responded = 0


      begin
        if threaded
          hosts_responded = threaded_req(request, publish_timeout, timeout, waitfor, &block)
        else
          hosts_responded = unthreaded_req(request, publish_timeout, timeout, waitfor, &block)
        end
      rescue Interrupt => e
      ensure
        unsubscribe(agent, :reply)
      end

      return update_stat(stat, hosts_responded, request.requestid)
    end

    # Starts the client receiver and publisher unthreaded.
    # This is the default client behaviour.
    def unthreaded_req(request, publish_timeout, timeout, waitfor, &block)
      start_publisher(request, publish_timeout)
      start_receiver(request.requestid, waitfor, timeout, &block)
    end

    # Starts the client receiver and publisher in threads.
    # This is activated when the 'threader_client' configuration
    # option is set.
    def threaded_req(request, publish_timeout, timeout, waitfor, &block)
      Log.debug("Starting threaded client")
      publisher = Thread.new do
        start_publisher(request, publish_timeout)
      end

      # When the client is threaded we add the publishing timeout to
      # the agent timeout so that the receiver doesn't time out before
      # publishing has finished in cases where publish_timeout >= timeout.
      total_timeout = publish_timeout + timeout
      hosts_responded = 0

      receiver = Thread.new do
        hosts_responded = start_receiver(request.requestid, waitfor, total_timeout, &block)
      end

      receiver.join
      hosts_responded
    end

    # Starts the request publishing routine
    def start_publisher(request, publish_timeout)
      Log.debug("Starting publishing with publish timeout of #{publish_timeout}")
      begin
        Timeout.timeout(publish_timeout) do
          Log.debug("Sending request #{request.requestid} to the #{request.agent} agent with ttl #{request.ttl} in collective #{request.collective}")
          request.publish
        end
      rescue Timeout::Error => e
        Log.warn("Could not publish all messages. Publishing timed out.")
      end
    end

    # Starts the response receiver routine
    # Expected to return the amount of received responses.
    def start_receiver(requestid, waitfor, timeout, &block)
      Log.debug("Starting response receiver with timeout of #{timeout}")
      hosts_responded = 0
      begin
        Timeout.timeout(timeout) do
          begin
            resp = receive(requestid)
            yield resp.payload
            hosts_responded += 1
          end while (waitfor == 0 || hosts_responded < waitfor)
        end
      rescue Timeout::Error => e
        if (waitfor > hosts_responded)
          Log.warn("Could not receive all responses. Expected : #{waitfor}. Received : #{hosts_responded}")
        end
      end

      hosts_responded
    end

    def update_stat(stat, hosts_responded, requestid)
      stat[:totaltime] = Time.now.to_f - stat[:starttime]
      stat[:blocktime] = stat[:totaltime] - stat[:discoverytime]
      stat[:responses] = hosts_responded
      stat[:noresponsefrom] = []
      stat[:requestid] = requestid

      @stats = stat
    end

    def discovered_req(body, agent, options=false)
      raise "Client#discovered_req has been removed, please port your agent and client to the SimpleRPC framework"
    end

    # Prints out the stats returns from req and discovered_req in a nice way
    def display_stats(stats, options=false, caption="stomp call summary")
      options = @options unless options

      if options[:verbose]
        puts("\n---- #{caption} ----")

        if stats[:discovered]
          puts("           Nodes: #{stats[:discovered]} / #{stats[:responses]}")
        else
          puts("           Nodes: #{stats[:responses]}")
        end

        printf("      Start Time: %s\n", Time.at(stats[:starttime]))
        printf("  Discovery Time: %.2fms\n", stats[:discoverytime] * 1000)
        printf("      Agent Time: %.2fms\n", stats[:blocktime] * 1000)
        printf("      Total Time: %.2fms\n", stats[:totaltime] * 1000)

      else
        if stats[:discovered]
          printf("\nFinished processing %d / %d hosts in %.2f ms\n\n", stats[:responses], stats[:discovered], stats[:blocktime] * 1000)
        else
          printf("\nFinished processing %d hosts in %.2f ms\n\n", stats[:responses], stats[:blocktime] * 1000)
        end
      end

      if stats[:noresponsefrom].size > 0
        puts("\nNo response from:\n")

        stats[:noresponsefrom].each do |c|
          puts if c % 4 == 1
          printf("%30s", c)
        end

        puts
      end
    end
  end
end
