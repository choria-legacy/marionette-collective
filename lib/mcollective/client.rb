module MCollective
  class MsgDoesNotMatchRequestID < RuntimeError; end

  # Helpers for writing clients that can talk to agents, do discovery and so forth
  class Client
    attr_accessor :options, :stats

    def initialize(configfile)
      @config = Config.instance
      @config.loadconfig(configfile) unless @config.configured

      @connection = PluginManager["connector_plugin"]
      @security = PluginManager["security_plugin"]

      @security.initiated_by = :client
      @options = nil
      @subscriptions = {}

      @connection.connect
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
      if msg.is_a?(Message)
        request = msg
        agent = request.agent
      else
        ttl = @options[:ttl] || @config.ttl
        request = Message.new(msg, nil, {:agent => agent, :type => :request, :collective => collective, :filter => filter, :ttl => ttl})
      end

      request.encode!

      Log.debug("Sending request #{request.requestid} to the #{request.agent} agent with ttl #{request.ttl} in collective #{request.collective}")

      unless @subscriptions.include?(agent)
        subscription = Util.make_subscriptions(agent, :reply, collective)
        Log.debug("Subscribing to reply target for agent #{agent}")

        Util.subscribe(subscription)
        @subscriptions[agent] = 1
      end

      request.publish

      request.requestid
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

        reply.decode!

        reply.payload[:senderid] = Digest::MD5.hexdigest(reply.payload[:senderid]) if ENV.include?("MCOLLECTIVE_ANON")

        raise(MsgDoesNotMatchRequestID, "Message reqid #{requestid} does not match our reqid #{reply.requestid}") unless reply.requestid == requestid
      rescue SecurityValidationFailed => e
        Log.warn("Ignoring a message that did not pass security validations")
        retry
      rescue MsgDoesNotMatchRequestID => e
        Log.debug("Ignoring a message for some other client")
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
      raise "Limit has to be an integer" unless limit.is_a?(Fixnum)

      begin
        hosts = []
        Timeout.timeout(timeout) do
          reqid = sendreq("ping", "discovery", filter)
          Log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")

          loop do
            reply = receive(reqid)
            Log.debug("Got discovery reply from #{reply.payload[:senderid]}")
            hosts << reply.payload[:senderid]

            return hosts if limit > 0 && hosts.size == limit
          end
        end
      rescue Timeout::Error => e
        hosts.sort
      rescue Exception => e
        raise
      end
    end

    # Send a request, performs the passed block for each response
    #
    # times = req("status", "mcollectived", options, client) {|resp|
    #   pp resp
    # }
    #
    # It returns a hash of times and timeouts for discovery and total run is taken from the options
    # hash which in turn is generally built using MCollective::Optionparser
    def req(body, agent=nil, options=false, waitfor=0)
      if body.is_a?(Message)
        agent = body.agent
        options = body.options
        waitfor = body.discovered_hosts.size || 0
      end

      stat = {:starttime => Time.now.to_f, :discoverytime => 0, :blocktime => 0, :totaltime => 0}

      options = @options unless options

      STDOUT.sync = true

      hosts_responded = 0

      begin
        Timeout.timeout(options[:timeout]) do
          reqid = sendreq(body, agent, options[:filter])

          loop do
            resp = receive(reqid)

            hosts_responded += 1

            yield(resp.payload)

            break if (waitfor != 0 && hosts_responded >= waitfor)
          end
        end
      rescue Interrupt => e
      rescue Timeout::Error => e
      end

      stat[:totaltime] = Time.now.to_f - stat[:starttime]
      stat[:blocktime] = stat[:totaltime] - stat[:discoverytime]
      stat[:responses] = hosts_responded
      stat[:noresponsefrom] = []

      @stats = stat
      return stat
    end

    # Performs a discovery and then send a request, performs the passed block for each response
    #
    #    times = discovered_req("status", "mcollectived", options, client) {|resp|
    #       pp resp
    #    }
    #
    # It returns a hash of times and timeouts for discovery and total run is taken from the options
    # hash which in turn is generally built using MCollective::Optionparser
    def discovered_req(body, agent, options=false)
      stat = {:starttime => Time.now.to_f, :discoverytime => 0, :blocktime => 0, :totaltime => 0}

      options = @options unless options

      STDOUT.sync = true

      print("Determining the amount of hosts matching filter for #{options[:disctimeout]} seconds .... ")

      begin
        discovered_hosts = discover(options[:filter], options[:disctimeout])
        discovered = discovered_hosts.size
        hosts_responded = []
        hosts_not_responded = discovered_hosts

        stat[:discoverytime] = Time.now.to_f - stat[:starttime]

        puts("#{discovered}\n\n")
      rescue Interrupt
        puts("Discovery interrupted.")
        exit!
      end

      raise("No matching clients found") if discovered == 0

      begin
        Timeout.timeout(options[:timeout]) do
          reqid = sendreq(body, agent, options[:filter])

          (1..discovered).each do |c|
            resp = receive(reqid)

            hosts_responded << resp.payload[:senderid]
            hosts_not_responded.delete(resp.payload[:senderid]) if hosts_not_responded.include?(resp.payload[:senderid])

            yield(resp.payload)
          end
        end
      rescue Interrupt => e
      rescue Timeout::Error => e
      end

      stat[:totaltime] = Time.now.to_f - stat[:starttime]
      stat[:blocktime] = stat[:totaltime] - stat[:discoverytime]
      stat[:responses] = hosts_responded.size
      stat[:responsesfrom] = hosts_responded
      stat[:noresponsefrom] = hosts_not_responded
      stat[:discovered] = discovered

      @stats = stat
      return stat
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

# vi:tabstop=4:expandtab:ai
