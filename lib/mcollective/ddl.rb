module MCollective
  # A class that helps creating data description language files
  # for plugins.  You can define meta data, actions, input and output
  # describing the behavior of your agent or other plugins
  #
  # Later you can access this information to assist with creating
  # of user interfaces or online help
  #
  # A sample DDL can be seen below, you'd put this in your agent
  # dir as <agent name>.ddl
  #
  #    metadata :name        => "SimpleRPC Service Agent",
  #             :description => "Agent to manage services using the Puppet service provider",
  #             :author      => "R.I.Pienaar",
  #             :license     => "GPLv2",
  #             :version     => "1.1",
  #             :url         => "http://mcollective-plugins.googlecode.com/",
  #             :timeout     => 60
  #
  #    action "status", :description => "Gets the status of a service" do
  #       display :always
  #
  #       input "service",
  #             :prompt      => "Service Name",
  #             :description => "The service to get the status for",
  #             :type        => :string,
  #             :validation  => '^[a-zA-Z\-_\d]+$',
  #             :optional    => true,
  #             :maxlength   => 30
  #
  #       output "status",
  #             :description => "The status of service",
  #             :display_as  => "Service Status"
  #   end
  class DDL
    attr_reader :meta, :entities

    def initialize(plugin, plugintype=:agent, loadddl=true)
      @entities = {}
      @meta = {}
      @config = Config.instance
      @plugin = plugin
      @plugintype = plugintype.to_sym

      if loadddl
        if ddlfile = findddlfile(plugin, plugintype)
          instance_eval(File.read(ddlfile))
        else
          raise("Can't find DDL for #{plugintype} plugin '#{plugin}'")
        end
      end
    end

    def findddlfile(ddlname, ddltype=:agent)
      @config.libdir.each do |libdir|
        ddlfile = File.join([libdir, "mcollective", ddltype.to_s, "#{ddlname}.ddl"])

        if File.exist?(ddlfile)
          Log.debug("Found #{ddlname} ddl at #{ddlfile}")
          return ddlfile
        end
      end
      return false
    end

    # Registers meta data for the introspection hash
    def metadata(meta)
      [:name, :description, :author, :license, :version, :url, :timeout].each do |arg|
        raise "Metadata needs a :#{arg} property" unless meta.include?(arg)
      end

      @meta = meta
    end

    # Creates the definition for a data query
    #
    #    dataquery :description => "Match data using Augeas" do
    #       input  :query,
    #              :prompt      => "Matcher",
    #              :description => "Valid Augeas match expression",
    #              :type        => :string,
    #              :validation  => /.+/,
    #              :maxlength   => 50
    #
    #       output :size,
    #              :description => "The amount of records matched",
    #              :display_as => "Matched"
    #    end
    def dataquery(input, &block)
      raise "Data queries need a :description" unless input.include?(:description)
      raise "Data queries can only have one definition" if @entities[:data]

      @entities[:data]  = {:description => input[:description],
                           :input => {},
                           :output => {}}

      @current_entity = :data
      block.call if block_given?
      @current_entity = nil
    end

    # Returns the interface for the data query
    def dataquery_interface
      raise "Only data DDLs have data queries" unless @plugintype == :data
      @entities[:data] || {}
    end

    # Creates the definition for an action, you can nest input definitions inside the
    # action to attach inputs and validation to the actions
    #
    #    action "status", :description => "Restarts a Service" do
    #       display :always
    #
    #       input  "service",
    #              :prompt      => "Service Action",
    #              :description => "The action to perform",
    #              :type        => :list,
    #              :optional    => true,
    #              :list        => ["start", "stop", "restart", "status"]
    #
    #       output "status",
    #              :description => "The status of the service after the action"
    #
    #    end
    def action(name, input, &block)
      raise "Action needs a :description property" unless input.include?(:description)

      unless @entities.include?(name)
        @entities[name] = {}
        @entities[name][:action] = name
        @entities[name][:input] = {}
        @entities[name][:output] = {}
        @entities[name][:display] = :failed
        @entities[name][:description] = input[:description]
      end

      # if a block is passed it might be creating input methods, call it
      # we set @current_entity so the input block can know what its talking
      # to, this is probably an epic hack, need to improve.
      @current_entity = name
      block.call if block_given?
      @current_entity = nil
    end

    # Registers an input argument for a given action
    #
    # See the documentation for action for how to use this
    def input(argument, properties)
      raise "Cannot figure out what entity input #{argument} belongs to" unless @current_entity

      entity = @current_entity

      raise "The only valid input name for a data query is 'query'" if @plugintype == :data && argument != :query

      if @plugintype == :agent
        raise "Input needs a :optional property" unless properties.include?(:optional)
      end

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
                                              :display_as  => properties[:display_as]}
    end

    # Sets the display preference to either :ok, :failed, :flatten or :always
    # operates on action level
    def display(pref)
      # defaults to old behavior, complain if its supplied and invalid
      unless [:ok, :failed, :flatten, :always].include?(pref)
        raise "Display preference #{pref} is not valid, should be :ok, :failed, :flatten or :always"
      end

      action = @current_entity
      @entities[action][:display] = pref
    end

    def template_for_plugintype
      case @plugintype
        when :agent
          return "rpc-help.erb"
        else
          return "#{@plugintype}-help.erb"
      end
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

    # Returns an array of actions this agent support
    def actions
      raise "Only agent DDLs have actions" unless @plugintype == :agent
      @entities.keys
    end

    # Returns the interface for a specific action
    def action_interface(name)
      raise "Only agent DDLs have actions" unless @plugintype == :agent
      @entities[name] || {}
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
          raise DDLValidationError, "Input #{key} should be a string" unless argument.is_a?(String)

          if input[key][:maxlength].to_i > 0
            if argument.size > input[key][:maxlength].to_i
              raise DDLValidationError, "Input #{key} is longer than #{input[key][:maxlength]} character(s)"
            end
          end

          unless argument.match(Regexp.new(input[key][:validation]))
            raise DDLValidationError, "Input #{key} does not match validation regex #{input[key][:validation]}"
          end

        when :list
          unless input[key][:list].include?(argument)
            raise DDLValidationError, "Input #{key} doesn't match list #{input[key][:list].join(', ')}"
          end

        when :boolean
          unless [TrueClass, FalseClass].include?(argument.class)
            raise DDLValidationError, "Input #{key} should be a boolean"
          end

        when :integer
          raise DDLValidationError, "Input #{key} should be a integer" unless argument.is_a?(Fixnum)

        when :float
          raise DDLValidationError, "Input #{key} should be a floating point number" unless argument.is_a?(Float)

        when :number
          raise DDLValidationError, "Input #{key} should be a number" unless argument.is_a?(Numeric)
      end
    end

    # Helper to use the DDL to figure out if the remote call to an
    # agent should be allowed based on action name and inputs.
    def validate_rpc_request(action, arguments)
      raise "Can only validate RPC requests against Agent DDLs" unless @plugintype == :agent

      # is the action known?
      unless actions.include?(action)
        raise DDLValidationError, "Attempted to call action #{action} for #{@plugin} but it's not declared in the DDL"
      end

      input = action_interface(action)[:input]

      input.keys.each do |key|
        unless input[key][:optional]
          unless arguments.keys.include?(key)
            raise DDLValidationError, "Action #{action} needs a #{key} argument"
          end
        end

        if arguments.keys.include?(key)
          validate_input_argument(input, key, arguments[key])
        end
      end

      true
    end
  end
end
