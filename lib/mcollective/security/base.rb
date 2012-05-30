module MCollective
  module Security
    # This is a base class the other security modules should inherit from
    # it handles statistics and validation of messages that should in most
    # cases apply to all security models.
    #
    # To create your own security plugin you should provide a plugin that inherits
    # from this and provides the following methods:
    #
    # decodemsg      - Decodes a message that was received from the middleware
    # encodereply    - Encodes a reply message to a previous request message
    # encoderequest  - Encodes a new request message
    # validrequest?  - Validates a request received from the middleware
    #
    # Optionally if you are identifying users by some other means like certificate name
    # you can provide your own callerid method that can provide the rest of the system
    # with an id, and you would see this id being usable in SimpleRPC authorization methods
    #
    # The @initiated_by variable will be set to either :client or :node depending on
    # who is using this plugin.  This is to help security providers that operate in an
    # asymetric mode like public/private key based systems.
    #
    # Specifics of each of these are a bit fluid and the interfaces for this is not
    # set in stone yet, specifically the encode methods will be provided with a helper
    # that takes care of encoding the core requirements.  The best place to see how security
    # works is by looking at the provided MCollective::Security::PSK plugin.
    class Base
      attr_reader :stats
      attr_accessor :initiated_by

      # Register plugins that inherits base
      def self.inherited(klass)
        PluginManager << {:type => "security_plugin", :class => klass.to_s}
      end

      # Initializes configuration and logging as well as prepare a zero'd hash of stats
      # various security methods and filter validators should increment stats, see MCollective::Security::Psk for a sample
      def initialize
        @config = Config.instance
        @log = Log
        @stats = PluginManager["global_stats"]
      end

      # Takes a Hash with a filter in it and validates it against host information.
      #
      # At present this supports filter matches against the following criteria:
      #
      # - puppet_class|cf_class - Presence of a configuration management class in
      #                           the file configured with classesfile
      # - agent - Presence of a MCollective agent with a supplied name
      # - fact - The value of a fact avout this system
      # - identity - the configured identity of the system
      #
      # TODO: Support REGEX and/or multiple filter keys to be AND'd
      def validate_filter?(filter)
        failed = 0
        passed = 0

        passed = 1 if Util.empty_filter?(filter)

        filter.keys.each do |key|
          case key
          when /puppet_class|cf_class/
            filter[key].each do |f|
              Log.debug("Checking for class #{f}")
              if Util.has_cf_class?(f) then
                Log.debug("Passing based on configuration management class #{f}")
                passed += 1
              else
                Log.debug("Failing based on configuration management class #{f}")
                failed += 1
              end
            end

          when "compound"
            filter[key].each do |compound|
              result = false
              truth_values = []

              begin
                compound.each do |expression|
                  case expression.keys.first
                    when "statement"
                      truth_values << Matcher.eval_compound_statement(expression).to_s
                    when "fstatement"
                      truth_values << Matcher.eval_compound_fstatement(expression.values.first)
                    when "and"
                      truth_values << "&&"
                    when "or"
                      truth_values << "||"
                    when "("
                      truth_values << "("
                    when ")"
                      truth_values << ")"
                    when "not"
                      truth_values << "!"
                  end
                end

                result = eval(truth_values.join(" "))
              rescue DDLValidationError
                result = false
              end

              if result
                Log.debug("Passing based on class and fact composition")
                passed +=1
              else
                Log.debug("Failing based on class and fact composition")
                failed +=1
              end
            end

          when "agent"
            filter[key].each do |f|
              if Util.has_agent?(f) || f == "mcollective"
                Log.debug("Passing based on agent #{f}")
                passed += 1
              else
                Log.debug("Failing based on agent #{f}")
                failed += 1
              end
            end

          when "fact"
            filter[key].each do |f|
              if Util.has_fact?(f[:fact], f[:value], f[:operator])
                Log.debug("Passing based on fact #{f[:fact]} #{f[:operator]} #{f[:value]}")
                passed += 1
              else
                Log.debug("Failing based on fact #{f[:fact]} #{f[:operator]} #{f[:value]}")
                failed += 1
              end
            end

          when "identity"
            unless filter[key].empty?
              # Identity filters should not be 'and' but 'or' as each node can only have one identity
              matched = filter[key].select{|f| Util.has_identity?(f)}.size

              if matched == 1
                Log.debug("Passing based on identity")
                passed += 1
              else
                Log.debug("Failed based on identity")
                failed += 1
              end
            end
          end
        end

        if failed == 0 && passed > 0
          Log.debug("Message passed the filter checks")

          @stats.passed

          return true
        else
          Log.debug("Message failed the filter checks")

          @stats.filtered

          return false
        end
      end

      def create_reply(reqid, agent, body)
        Log.debug("Encoded a message for request #{reqid}")

        {:senderid => @config.identity,
         :requestid => reqid,
         :senderagent => agent,
         :msgtime => Time.now.utc.to_i,
         :body => body}
      end

      def create_request(reqid, filter, msg, initiated_by, target_agent, target_collective, ttl=60)
        Log.debug("Encoding a request for agent '#{target_agent}' in collective #{target_collective} with request id #{reqid}")

        {:body => msg,
         :senderid => @config.identity,
         :requestid => reqid,
         :filter => filter,
         :collective => target_collective,
         :agent => target_agent,
         :callerid => callerid,
         :ttl => ttl,
         :msgtime => Time.now.utc.to_i}
      end

      # Give a MC::Message instance and a message id this will figure out if you the incoming
      # message id matches the one the Message object is expecting and raise if its not
      #
      # Mostly used by security plugins to figure out if they should do the hard work of decrypting
      # etc messages that would only later on be ignored
      def should_process_msg?(msg, msgid)
        if msg.expected_msgid
          unless msg.expected_msgid == msgid
            msgtext = "Got a message with id %s but was expecting %s, ignoring message" % [msgid, msg.expected_msgid]
            Log.debug msgtext
            raise MsgDoesNotMatchRequestID, msgtext
          end
        end

        true
      end

      # Validates a callerid.  We do not want to allow things like \ and / in
      # callerids since other plugins make assumptions that these are safe strings.
      #
      # callerids are generally in the form uid=123 or cert=foo etc so we do that
      # here but security plugins could override this for some complex uses
      def valid_callerid?(id)
        !!id.match(/^[\w]+=[\w\.\-]+$/)
      end

      # Returns a unique id for the caller, by default we just use the unix
      # user id, security plugins can provide their own means of doing ids.
      def callerid
        "uid=#{Process.uid}"
      end

      # Security providers should provide this, see MCollective::Security::Psk
      def validrequest?(req)
        Log.error("validrequest? is not implemented in #{self.class}")
      end

      # Security providers should provide this, see MCollective::Security::Psk
      def encoderequest(sender, msg, filter={})
        Log.error("encoderequest is not implemented in #{self.class}")
      end

      # Security providers should provide this, see MCollective::Security::Psk
      def encodereply(sender, msg, requestcallerid=nil)
        Log.error("encodereply is not implemented in #{self.class}")
      end

      # Security providers should provide this, see MCollective::Security::Psk
      def decodemsg(msg)
        Log.error("decodemsg is not implemented in #{self.class}")
      end
    end
  end
end
