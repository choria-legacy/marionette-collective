module MCollective
  module Data
    class Base
      attr_reader :name, :result, :ddl, :timeout

      # Register plugins that inherits base
      def self.inherited(klass)
        type = klass.to_s.split("::").last.downcase

        PluginManager << {:type => type, :class => klass.to_s, :single_instance => false}
      end

      def initialize
        @name = self.class.to_s.split("::").last.downcase
        @ddl = DDL.new(@name, :data)
        @result = Result.new(@ddl.dataquery_interface[:output])
        @timeout = @ddl.meta[:timeout] || 1

        startup_hook
      end

      def lookup(what)
        ddl_validate(what)

        Log.debug("Doing data query %s for '%s'" % [ @name, what ])

        Timeout::timeout(@timeout) do
          query_data(what)
        end

        @result
      rescue Timeout::Error
        # Timeout::Error is a inherited from Interrupt which seems a really
        # strange choice, making it an equivelant of ^C and such.  Catch it
        # and raise something less critical that will not the runner to just
        # give up the ghost
        msg = "Data plugin %s timed out on query '%s'" % [@name, what]
        Log.error(msg)
        raise MsgTTLExpired, msg
      end

      def self.query(&block)
        self.module_eval { define_method("query_data", &block) }
      end

      def ddl_validate(what)
        Data.ddl_validate(@ddl, what)
      end

      # activate_when do
      #    file.exist?("/usr/bin/puppet")
      # end
      def self.activate_when(&block)
        (class << self; self; end).instance_eval do
          define_method("activate?", &block)
        end
      end

      # Always be active unless a specific block is given with activate_when
      def self.activate?
        return true
      end

      def startup_hook;end
    end
  end
end
