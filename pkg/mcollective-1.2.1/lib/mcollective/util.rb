module MCollective
    # Some basic utility helper methods useful to clients, agents, runner etc.
    module Util
        # Finds out if this MCollective has an agent by the name passed
        #
        # If the passed name starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_agent?(agent)
            agent = Regexp.new(agent.gsub("\/", "")) if agent.match("^/")

            if agent.is_a?(Regexp)
                if Agents.agentlist.grep(agent).size > 0
                    return true
                else
                    return false
                end
            else
                return Agents.agentlist.include?(agent)
            end

            false
        end

        # Checks if this node has a configuration management class by parsing the
        # a text file with just a list of classes, recipes, roles etc.  This is
        # ala the classes.txt from puppet.
        #
        # If the passed name starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_cf_class?(klass)
            klass = Regexp.new(klass.gsub("\/", "")) if klass.match("^/")
            cfile = Config.instance.classesfile

            Log.debug("Looking for configuration management classes in #{cfile}")

            File.readlines(cfile).each do |k|
                if klass.is_a?(Regexp)
                    return true if k.chomp.match(klass)
                else
                    return true if k.chomp == klass
                end
            end

            false
        end

        # Gets the value of a specific fact, mostly just a duplicate of MCollective::Facts.get_fact
        # but it kind of goes with the other classes here
        def self.get_fact(fact)
            Facts.get_fact(fact)
        end

        # Compares fact == value,
        #
        # If the passed value starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_fact?(fact, value, operator)

            Log.debug("Comparing #{fact} #{operator} #{value}")
            Log.debug("where :fact = '#{fact}', :operator = '#{operator}', :value = '#{value}'")

            fact = Facts[fact]
            return false if fact.nil?

            fact = fact.clone

            if operator == '=~'
                # to maintain backward compat we send the value
                # as /.../ which is what 1.0.x needed.  this strips
                # off the /'s wich is what we need here
                if value =~ /^\/(.+)\/$/
                    value = $1
                end

                return true if fact.match(Regexp.new(value))

            elsif operator == "=="
                return true if fact == value

            elsif ['<=', '>=', '<', '>', '!='].include?(operator)
                # Yuk - need to type cast, but to_i and to_f are overzealous
                if value =~ /^[0-9]+$/ && fact =~ /^[0-9]+$/
                    fact = Integer(fact)
                    value = Integer(value)
                elsif value =~ /^[0-9]+.[0-9]+$/ && fact =~ /^[0-9]+.[0-9]+$/
                    fact = Float(fact)
                    value = Float(value)
                end

                return true if eval("fact #{operator} value")
            end

            false
        end

        # Checks if the configured identity matches the one supplied
        #
        # If the passed name starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_identity?(identity)
            identity = Regexp.new(identity.gsub("\/", "")) if identity.match("^/")

            if identity.is_a?(Regexp)
                return Config.instance.identity.match(identity)
            else
                return true if Config.instance.identity == identity
            end

            false
        end

        # Checks if the passed in filter is an empty one
        def self.empty_filter?(filter)
            filter == empty_filter || filter == {}
        end

        # Creates an empty filter
        def self.empty_filter
            {"fact"     => [],
             "cf_class" => [],
             "agent"    => [],
             "identity" => []}
        end

        # Picks a config file defaults to ~/.mcollective
        # else /etc/mcollective/client.cfg
        def self.config_file_for_user
            # expand_path is pretty lame, it relies on HOME environment
            # which isnt't always there so just handling all exceptions
            # here as cant find reverting to default
            begin
                config = File.expand_path("~/.mcollective")

                unless File.readable?(config) && File.file?(config)
                    config = "/etc/mcollective/client.cfg"
                end
            rescue Exception => e
                config = "/etc/mcollective/client.cfg"
            end

            return config
        end

        # Creates a standard options hash
        def self.default_options
            {:verbose     => false,
             :disctimeout => 2,
             :timeout     => 5,
             :config      => config_file_for_user,
             :collective  => nil,
             :filter      => empty_filter}
        end

        # Constructs an array of the full target names based on topicprefix,
        # topicsep and collectives config options.
        #
        # If given a collective name it will return a single target aimed
        # at just the one collective
        def self.make_target(agent, type, collective=nil)
            config = Config.instance

            raise("Unknown target type #{type}") unless type == :command || type == :reply

            if collective.nil?
                config.collectives.map do |c|
                    ["#{config.topicprefix}#{c}", agent, type].join(config.topicsep)
                end
            else
                raise("Unknown collective '#{collective}' known collectives are '#{config.collectives.join ', '}'") unless config.collectives.include?(collective)

                ["#{config.topicprefix}#{collective}", agent, type].join(config.topicsep)
            end
        end

        # Helper to subscribe to a topic on multiple collectives or just one
        def self.subscribe(topics)
            connection = PluginManager["connector_plugin"]

            if topics.is_a?(Array)
                topics.each do |topic|
                    connection.subscribe(topic)
                end
            else
                connection.subscribe(topics)
            end
        end

        # Helper to unsubscribe to a topic on multiple collectives or just one
        def self.unsubscribe(topics)
            connection = PluginManager["connector_plugin"]

            if topics.is_a?(Array)
                topics.each do |topic|
                    connection.unsubscribe(topic)
                end
            else
                connection.unsubscribe(topics)
            end
        end

        # Wrapper around PluginManager.loadclass
        def self.loadclass(klass)
            PluginManager.loadclass(klass)
        end

        # Parse a fact filter string like foo=bar into the tuple hash thats needed
        def self.parse_fact_string(fact)
            if fact =~ /^([^ ]+?)[ ]*=>[ ]*(.+)/
                return {:fact => $1, :value => $2, :operator => '>=' }
            elsif fact =~ /^([^ ]+?)[ ]*=<[ ]*(.+)/
                return {:fact => $1, :value => $2, :operator => '<=' }
            elsif fact =~ /^([^ ]+?)[ ]*(<=|>=|<|>|!=|==|=~)[ ]*(.+)/
                return {:fact => $1, :value => $3, :operator => $2 }
            elsif fact =~ /^(.+?)[ ]*=[ ]*\/(.+)\/$/
                return {:fact => $1, :value => "/#{$2}/", :operator => '=~' }
            elsif fact =~ /^([^= ]+?)[ ]*=[ ]*(.+)/
                return {:fact => $1, :value => $2, :operator => '==' }
            end

            return false
        end

        # Escapes a string so it's safe to use in system() or backticks
        #
        # Taken from Shellwords#shellescape since it's only in a few ruby versions
        def self.shellescape(str)
            return "''" if str.empty?

            str = str.dup

            # Process as a single byte sequence because not all shell
            # implementations are multibyte aware.
            str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")

            # A LF cannot be escaped with a backslash because a backslash + LF
            # combo is regarded as line continuation and simply ignored.
            str.gsub!(/\n/, "'\n'")

            return str
        end

        # Parse the msgtarget as sent in 1.1.4 and newer to figure out the
        # agent and collective that a request is targeted at
        def self.parse_msgtarget(target)
            sep = Regexp.escape(Config.instance.topicsep)
            prefix = Regexp.escape(Config.instance.topicprefix)
            regex = "#{prefix}(.+?)#{sep}(.+?)#{sep}command"

            if target.match(regex)
                return {:collective => $1, :agent => $2}
            else
                raise "Failed to handle message, could not figure out agent and collective from #{target}"
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
