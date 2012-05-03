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
    attr_reader :meta

    def initialize(agent, loadddl=true)
      @actions = {}
      @meta = {}
      @config = MCollective::Config.instance
      @agent = agent

      if loadddl
        if ddlfile = findddlfile(agent)
          instance_eval(File.read(ddlfile))
        else
          raise("Can't find DDL for agent '#{agent}'")
        end
      end
    end

    def findddlfile(agent)
      @config.libdir.each do |libdir|
        ddlfile = File.join([libdir, "mcollective", "agent", "#{agent}.ddl"])

        if File.exist?(ddlfile)
          Log.debug("Found #{agent} ddl at #{ddlfile}")
          return ddlfile
        end
      end
      return false
    end

    # Registers meta data for the introspection hash
    def metadata(meta)
      [:name, :description, :author, :license, :version, :url, :timeout].each do |arg|
        raise "Metadata needs a :#{arg}" unless meta.include?(arg)
      end

      @meta = meta
    end

    # Creates the definition for an action, you can nest input definitions inside the
    # action to attach inputs and validation to the actions
    #
    #    action "status", :description => "Restarts a Service" do
    #       display :always
    #
    #       input "service",
    #            :prompt      => "Service Action",
    #            :description => "The action to perform",
    #            :type        => :list,
    #            :optional    => true,
    #            :list        => ["start", "stop", "restart", "status"]
    #
    #       output "status"
    #            :description => "The status of the service after the action"
    #
    #    end
    def action(name, input, &block)
      raise "Action needs a :description" unless input.include?(:description)

      unless @actions.include?(name)
        @actions[name] = {}
        @actions[name][:action] = name
        @actions[name][:input] = {}
        @actions[name][:output] = {}
        @actions[name][:display] = :failed
        @actions[name][:description] = input[:description]
      end

      # if a block is passed it might be creating input methods, call it
      # we set @current_action so the input block can know what its talking
      # to, this is probably an epic hack, need to improve.
      @current_action = name
      block.call if block_given?
      @current_action = nil
    end

    # Registers an input argument for a given action
    #
    # See the documentation for action for how to use this
    def input(argument, properties)
      raise "Cannot figure out what action input #{argument} belongs to" unless @current_action

      action = @current_action

      [:prompt, :description, :type, :optional].each do |arg|
        raise "Input needs a :#{arg}" unless properties.include?(arg)
      end

      @actions[action][:input][argument] = {:prompt => properties[:prompt],
        :description => properties[:description],
        :type => properties[:type],
        :optional => properties[:optional]}

      case properties[:type]
        when :string
          raise "Input type :string needs a :validation argument" unless properties.include?(:validation)
          raise "Input type :string needs a :maxlength argument" unless properties.include?(:maxlength)

          @actions[action][:input][argument][:validation] = properties[:validation]
          @actions[action][:input][argument][:maxlength] = properties[:maxlength]

        when :list
          raise "Input type :list needs a :list argument" unless properties.include?(:list)

          @actions[action][:input][argument][:list] = properties[:list]
      end
    end

    # Registers an output argument for a given action
    #
    # See the documentation for action for how to use this
    def output(argument, properties)
      raise "Cannot figure out what action input #{argument} belongs to" unless @current_action
      raise "Output #{argument} needs a description argument" unless properties.include?(:description)
      raise "Output #{argument} needs a display_as argument" unless properties.include?(:display_as)

      action = @current_action

      @actions[action][:output][argument] = {:description => properties[:description],
        :display_as  => properties[:display_as]}
    end

    # Sets the display preference to either :ok, :failed, :flatten or :always
    # operates on action level
    def display(pref)
      # defaults to old behavior, complain if its supplied and invalid
      unless [:ok, :failed, :flatten, :always].include?(pref)
        raise "Display preference #{pref} is not valid, should be :ok, :failed, :flatten or :always"
      end

      action = @current_action
      @actions[action][:display] = pref
    end

    # Generates help using the template based on the data
    # created with metadata and input
    def help(template)
      template = IO.read(template)
      meta = @meta
      actions = @actions

      erb = ERB.new(template, 0, '%')
      erb.result(binding)
    end

    # Returns an array of actions this agent support
    def actions
      @actions.keys
    end

    # Returns the interface for a specific action
    def action_interface(name)
      @actions[name] || {}
    end

    # Helper to use the DDL to figure out if the remote call to an
    # agent should be allowed based on action name and inputs.
    def validate_rpc_request(action, arguments)
      # is the action known?
      unless actions.include?(action)
        raise DDLValidationError, "Attempted to call action #{action} for #{@agent} but it's not declared in the DDL"
      end

      input = action_interface(action)[:input]

      input.keys.each do |key|
        unless input[key][:optional]
          unless arguments.keys.include?(key)
            raise DDLValidationError, "Action #{action} needs a #{key} argument"
          end
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
        if arguments.keys.include?(key)
          case input[key][:type]
            when :string
              raise DDLValidationError, "Input #{key} should be a string" unless arguments[key].is_a?(String)

              if input[key][:maxlength].to_i > 0
                if arguments[key].size > input[key][:maxlength].to_i
                  raise DDLValidationError, "Input #{key} is longer than #{input[key][:maxlength]} character(s)"
                end
              end

              unless arguments[key].match(Regexp.new(input[key][:validation]))
                raise DDLValidationError, "Input #{key} does not match validation regex #{input[key][:validation]}"
              end

            when :list
              unless input[key][:list].include?(arguments[key])
                raise DDLValidationError, "Input #{key} doesn't match list #{input[key][:list].join(', ')}"
              end

            when :boolean
              unless [TrueClass, FalseClass].include?(arguments[key].class)
                raise DDLValidationError, "Input #{key} should be a boolean"
              end

            when :integer
              raise DDLValidationError, "Input #{key} should be a integer" unless arguments[key].is_a?(Fixnum)

            when :float
              raise DDLValidationError, "Input #{key} should be a floating point number" unless arguments[key].is_a?(Float)

            when :number
              raise DDLValidationError, "Input #{key} should be a number" unless arguments[key].is_a?(Numeric)
          end
        end
      end

      true
    end
  end
end
