module MCollective
  # A set of classes that helps create data description language files
  # for plugins.  You can define meta data, actions, input and output
  # describing the behavior of your agent or other plugins
  #
  # DDL files are used for input validation, constructing outputs,
  # producing online help, informing the various display routines and
  # so forth.
  #
  # A sample DDL for an agent be seen below, you'd put this in your agent
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
  #       input :service,
  #             :prompt      => "Service Name",
  #             :description => "The service to get the status for",
  #             :type        => :string,
  #             :validation  => '^[a-zA-Z\-_\d]+$',
  #             :optional    => true,
  #             :maxlength   => 30
  #
  #       output :status,
  #              :description => "The status of service",
  #              :display_as  => "Service Status"
  #   end
  #
  # There are now many types of DDL and ultimately all pugins should have
  # DDL files.  The code is organized so that any plugin type will magically
  # just work - they will be an instane of Base which has #metadata and a few
  # common cases.
  #
  # For plugin types that require more specific behaviors they can just add a
  # class here that inherits from Base and add their specific behavior.
  #
  # Base defines a specific behavior for input, output and metadata which we'd
  # like to keep standard across plugin types so do not completely override the
  # behavior of input.  The methods are written that they will gladly store extra
  # content though so you add, do not remove.  See the AgentDDL class for an example
  # where agents want a :required argument to be always set.
  module DDL
    require "mcollective/ddl/base"
    require "mcollective/ddl/agentddl"
    require "mcollective/ddl/dataddl"
    require "mcollective/ddl/discoveryddl"

    # There used to be only one big nasty DDL class with a bunch of mashed
    # together behaviors.  It's been around for ages and we would rather not
    # ask all the users to change their DDL.new calls to some other factory
    # method that would have this exact same behavior.
    #
    # So we override the behavior of #new which is a hugely sucky thing to do
    # but ultimately it's what would be least disrupting to code out there
    # today.  We did though change DDL to a module to make it possibly a
    # little less suprising, possibly.
    def self.new(*args, &blk)
      load_and_cache(*args)
    end

    def self.load_and_cache(*args)
      Cache.setup(:ddl, 300)

      plugin = args.first
      args.size > 1 ? type = args[1].to_s : type = "agent"
      path = "%s/%s" % [type, plugin]

      begin
        ddl = Cache.read(:ddl, path)
      rescue
        begin
          klass = DDL.const_get("%sDDL" % type.capitalize)
        rescue NameError
          klass = Base
        end

        ddl = Cache.write(:ddl, path, klass.new(*args))
      end

      return ddl
    end

    # As we're taking arguments on the command line we need a
    # way to input booleans, true on the cli is a string so this
    # method will take the ddl, find all arguments that are supposed
    # to be boolean and if they are the strings "true"/"yes" or "false"/"no"
    # turn them into the matching boolean
    def self.string_to_boolean(val)
      return true if ["true", "t", "yes", "y", "1"].include?(val.downcase)
      return false if ["false", "f", "no", "n", "0"].include?(val.downcase)

      raise "#{val} does not look like a boolean argument"
    end

    # a generic string to number function, if a number looks like a float
    # it turns it into a float else an int.  This is naive but should be sufficient
    # for numbers typed on the cli in most cases
    def self.string_to_number(val)
      return val.to_f if val =~ /^\d+\.\d+$/
      return val.to_i if val =~ /^\d+$/

      raise "#{val} does not look like a number"
    end
  end
end
