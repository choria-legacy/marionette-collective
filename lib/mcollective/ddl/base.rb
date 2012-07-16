module MCollective
  module DDL
    # The base class for all kinds of DDL files.  DDL files when
    # run gets parsed and builds up a hash of the basic primitive
    # types, ideally restricted so it can be converted to JSON though
    # today there are some Ruby Symbols in them which might be fixed
    # laster on.
    #
    # The Hash being built should be stored in @entities, the format
    # is generally not prescribed but there's a definite feel to how
    # DDL files look so study the agent and discovery ones to see how
    # the structure applies to very different use cases.
    #
    # For every plugin type you should have a single word name - that
    # corresponds to the directory in the libdir where these plugins
    # live.  If you need anything above and beyond 'metadata' in your
    # plugin DDL then add a PlugintypeDDL class here and add your
    # specific behaviors to those.
    class Base
      attr_reader :meta, :entities, :pluginname, :plugintype

      def initialize(plugin, plugintype=:agent, loadddl=true)
        @entities = {}
        @meta = {}
        @config = Config.instance
        @pluginname = plugin
        @plugintype = plugintype.to_sym

        loadddlfile if loadddl
      end

      # Generates help using the template based on the data
      # created with metadata and input.
      #
      # If no template name is provided one will be chosen based
      # on the plugin type.  If the provided template path is
      # not absolute then the template will be loaded relative to
      # helptemplatedir configuration parameter
      def help(template=nil)
        template = template_for_plugintype unless template
        template = File.join(@config.helptemplatedir, template) unless template.start_with?(File::SEPARATOR)

        template = File.read(template)
        meta = @meta
        entities = @entities

        erb = ERB.new(template, 0, '%')
        erb.result(binding)
      end

      def template_for_plugintype
        case @plugintype
        when :agent
          return "rpc-help.erb"
        else
          return "#{@plugintype}-help.erb"
        end
      end

      def loadddlfile
        if ddlfile = findddlfile
          instance_eval(File.read(ddlfile), ddlfile, 1)
        else
          raise("Can't find DDL for #{@plugintype} plugin '#{@pluginname}'")
        end
      end

      def findddlfile(ddlname=nil, ddltype=nil)
        ddlname = @pluginname unless ddlname
        ddltype = @plugintype unless ddltype

        @config.libdir.each do |libdir|
          ddlfile = File.join([libdir, "mcollective", ddltype.to_s, "#{ddlname}.ddl"])

          if File.exist?(ddlfile)
            Log.debug("Found #{ddlname} ddl at #{ddlfile}")
            return ddlfile
          end
        end
        return false
      end

      # validate strings, lists and booleans, we'll add more types of validators when
      # all the use cases are clear
      #
      # only does validation for arguments actually given, since some might
      # be optional.  We validate the presense of the argument earlier so
      # this is a safe assumption, just to skip them.
      #
      # :string can have maxlength and regex.  A maxlength of 0 will bypasss checks
      # :list has a array of valid values
      def validate_input_argument(input, key, argument)
        case input[key][:type]
          when :string
            raise DDLValidationError, "Input #{key} should be a string for plugin #{meta[:name]}" unless argument.is_a?(String)

            if input[key][:maxlength].to_i > 0
              if argument.size > input[key][:maxlength].to_i
                raise DDLValidationError, "Input #{key} is longer than #{input[key][:maxlength]} character(s) for plugin #{meta[:name]}"
              end
            end

            unless argument.match(Regexp.new(input[key][:validation]))
              raise DDLValidationError, "Input #{key} does not match validation regex #{input[key][:validation]} for plugin #{meta[:name]}"
            end

          when :list
            unless input[key][:list].include?(argument)
              raise DDLValidationError, "Input #{key} doesn't match list #{input[key][:list].join(', ')} for plugin #{meta[:name]}"
            end

          when :boolean
            unless [TrueClass, FalseClass].include?(argument.class)
              raise DDLValidationError, "Input #{key} should be a boolean for plugin #{meta[:name]}"
            end

          when :integer
            raise DDLValidationError, "Input #{key} should be a integer for plugin #{meta[:name]}" unless argument.is_a?(Fixnum)

          when :float
            raise DDLValidationError, "Input #{key} should be a floating point number for plugin #{meta[:name]}" unless argument.is_a?(Float)

          when :number
            raise DDLValidationError, "Input #{key} should be a number for plugin #{meta[:name]}" unless argument.is_a?(Numeric)
        end

        return true
      end

      # Registers an input argument for a given action
      #
      # See the documentation for action for how to use this
      def input(argument, properties)
        raise "Cannot figure out what entity input #{argument} belongs to" unless @current_entity

        entity = @current_entity

        [:prompt, :description, :type].each do |arg|
          raise "Input needs a :#{arg} property" unless properties.include?(arg)
        end

        @entities[entity][:input][argument] = {:prompt => properties[:prompt],
                                               :description => properties[:description],
                                               :type => properties[:type],
                                               :optional => properties[:optional]}

        case properties[:type]
          when :string
            raise "Input type :string needs a :validation argument" unless properties.include?(:validation)
            raise "Input type :string needs a :maxlength argument" unless properties.include?(:maxlength)

            @entities[entity][:input][argument][:validation] = properties[:validation]
            @entities[entity][:input][argument][:maxlength] = properties[:maxlength]

          when :list
            raise "Input type :list needs a :list argument" unless properties.include?(:list)

            @entities[entity][:input][argument][:list] = properties[:list]
        end
      end

      # Registers an output argument for a given action
      #
      # See the documentation for action for how to use this
      def output(argument, properties)
        raise "Cannot figure out what action input #{argument} belongs to" unless @current_entity
        raise "Output #{argument} needs a description argument" unless properties.include?(:description)
        raise "Output #{argument} needs a display_as argument" unless properties.include?(:display_as)

        action = @current_entity

        @entities[action][:output][argument] = {:description => properties[:description],
                                                :display_as  => properties[:display_as],
                                                :default     => properties[:default]}
      end


      # Registers meta data for the introspection hash
      def metadata(meta)
        [:name, :description, :author, :license, :version, :url, :timeout].each do |arg|
          raise "Metadata needs a :#{arg} property" unless meta.include?(arg)
        end

        @meta = meta
      end
    end
  end
end
