module MCollective
  module Registration
    # This is a base class that other registration plugins can use
    # to handle regular announcements to the mcollective
    #
    # The configuration file determines how often registration messages
    # gets sent using the _registerinterval_ option, the plugin runs in the
    # background in a thread.
    class Base
      # Register plugins that inherits base
      def self.inherited(klass)
        PluginManager << {:type => "registration_plugin", :class => klass.to_s}
      end

      # Creates a background thread that periodically send a registration notice.
      #
      # The actual registration notices comes from the 'body' method of the registration
      # plugins.
      def run(connection)
        return false if interval == 0

        Thread.new do
          publish_thread(connection)
        end
      end

      def config
        Config.instance
      end

      def msg_filter
        filter = Util.empty_filter
        filter["agent"] << "registration"
        filter
      end

      def target_collective
        main_collective = config.main_collective

        collective = config.registration_collective || main_collective

        unless config.collectives.include?(collective)
          Log.warn("Sending registration to #{main_collective}: #{collective} is not a valid collective")
          collective = main_collective
        end

        return collective
      end

      def interval
        config.registerinterval
      end

      def publish(message)
        unless message
          Log.debug("Skipping registration due to nil body")
        else
          req = Message.new(message, nil, {:type => :request, :agent => "registration", :collective => target_collective, :filter => msg_filter})
          req.encode!

          Log.debug("Sending registration #{req.requestid} to collective #{req.collective}")

          req.publish
        end
      end

      def body
        raise "Registration Plugins must implement the #body method"
      end

      private
      def publish_thread(connnection)
        if config.registration_splay
            splay_delay = rand(interval)
            Log.debug("registration_splay enabled. Registration will start in #{splay_delay} seconds")
            sleep splay_delay
          end

          loop do
            begin
              publish(body)
              sleep interval
            rescue Exception => e
              Log.error("Sending registration message failed: #{e}")
              sleep interval
            end
          end
      end
    end
  end
end
