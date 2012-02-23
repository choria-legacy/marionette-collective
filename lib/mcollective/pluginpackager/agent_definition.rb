module MCollective
  module PluginPackager
    # MCollective Agent Plugin package
    class AgentDefinition
      attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :iteration, :postinstall

      def initialize(path, name, vendor, postinstall, iteration)
        @path = path
        @packagedata = {}
        @iteration = iteration || 1
        @postinstall = postinstall
        @vendor = vendor || "Puppet Labs"
        @target_path = File.expand_path(@path)
        @metadata = get_metadata
        @metadata[:name] = name if name
        @metadata[:name] = @metadata[:name].downcase.gsub(" ", "_")
        identify_packages
      end

      # Identify present packages and populate packagedata hash.
      def identify_packages
        @packagedata[:common] = common
        @packagedata[:agent] = agent
        @packagedata[:client] = client
      end

      # Obtain Agent package files and dependencies.
      def agent
        agent = {:files => [],
                 :dependencies => ["mcollective"],
                 :description => "Agent plugin for #{@metadata[:name]}"}

        agentdir = File.join(@path, "agent")

        if check_dir agentdir
          ddls = Dir.glob "#{agentdir}/*.ddl"
          agent[:files] = (Dir.glob("#{agentdir}/*") - ddls)
          implementations = Dir.glob("#{@metadata[:name]}/**")
          agent[:files] += implementations unless implementations.empty?
        else
          return nil
        end

        agent[:dependencies] << "mcollective-#{@metadata[:name]}-common" if @packagedata[:common]
        agent
      end

      # Obtain client package files and dependencies.
      def client
        client = {:files => [],
                  :dependencies => ["mcollective-client"],
                  :description => "Client plugin for #{@metadata[:name]}"}

        clientdir = File.join(@path, "application")
        bindir = File.join(@path, "bin")
        ddldir = File.join(@path, "agent")

        client[:files] += Dir.glob("#{clientdir}/*") if check_dir clientdir
        client[:files] += Dir.glob("#{bindir}/*") if check_dir bindir
        client[:files] += Dir.glob("#{ddldir}/*.ddl") if check_dir ddldir
        client[:dependencies] << "mcollective-#{@metadata[:name]}-common" if @packagedata[:common]
        client[:files].empty? ? nil : client
      end

      # Obtain common package files and dependencies.
      def common
        common = {:files =>[],
                  :dependencies => ["mcollective-common"],
                  :description => "Common libraries for #{@metadata[:name]}"}

        commondir = File.join(@path, "util")
        common[:files] += Dir.glob("#{commondir}/*") if check_dir commondir
        common[:files].empty? ? nil : common
      end

      # Load plugin meta data from ddl file.
      def get_metadata
        ddl = MCollective::RPC::DDL.new("package", false)
        ddl.instance_eval File.read(Dir.glob("#{@path}/agent/*.ddl").first)
        ddl.meta
      rescue
        raise "error: could not read agent DDL File"
      end

      # Check if directory is present and not empty.
      def check_dir(path)
        (File.directory?(path) && !Dir.glob(path).empty?) ? true : false
      end
    end
  end
end
