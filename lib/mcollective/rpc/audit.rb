module MCollective
  module RPC
    # Auditing of requests is done only for SimpleRPC requests, you provide
    # a plugin in the MCollective::Audit::* namespace which the SimpleRPC
    # framework calls for each message
    #
    # We provide a simple one that logs to a logfile in the class
    # MCollective::Audit::Logfile you can create your own:
    #
    # Create a class in plugins/mcollective/audit/<yourplugin>.rb
    #
    # You must inherit from MCollective::RPC::Audit which will take
    # care of registering you with the plugin system.
    #
    # Your plugin must provide audit_request(request, connection)
    # the request parameter will be an instance of MCollective::RPC::Request
    #
    # To enable auditing you should set:
    #
    # rpcaudit = 1
    # rpcauditprovider = Logfile
    #
    # in the config file this will enable logging using the
    # MCollective::Audit::Logile class
    #
    # The Audit class acts as a base for audit plugins and takes care of registering them
    # with the plugin manager
    class Audit
      def self.inherited(klass)
        PluginManager << {:type => "rpcaudit_plugin", :class => klass.to_s}
      end

      def audit_request(request, connection)
        @log.error("audit_request is not implimented in #{this.class}")
      end
    end
  end
end
