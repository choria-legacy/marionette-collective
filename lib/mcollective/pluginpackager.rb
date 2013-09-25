module MCollective
  module PluginPackager
    # Plugin definition classes
    autoload :AgentDefinition, "mcollective/pluginpackager/agent_definition"
    autoload :StandardDefinition, "mcollective/pluginpackager/standard_definition"

    # Package implementation plugins
    def self.load_packagers
      PluginManager.find_and_load("pluginpackager")
    end

    def self.[](klass)
      const_get("#{klass}")
    end

    # Fetch and return metadata from plugin DDL
    def self.get_metadata(path, type)
      ddl = DDL.new("package", type.to_sym, false)

      begin
        ddl_file = File.read(Dir.glob(File.join(path, type, "*.ddl")).first)
      rescue Exception
        raise "failed to load ddl file in plugin directory : #{File.join(path, type)}"
      end
      ddl.instance_eval ddl_file

      return ddl.meta, ddl.requirements[:mcollective]
    end

    # Checks if a directory is present and not empty
    def self.check_dir_present(path)
      (File.directory?(path) && !Dir.glob(File.join(path, "*")).empty?)
    end

    # Quietly calls a block if verbose parameter is false
    def self.execute_verbosely(verbose, &block)
      unless verbose
        old_stdout = $stdout.clone
        $stdout.reopen(File.new("/dev/null", "w"))
        begin
          block.call
        rescue Exception => e
          $stdout.reopen old_stdout
          raise e
        ensure
          $stdout.reopen old_stdout
        end
      else
        block.call
      end
    end

    # Checks if a build tool is present on the system
    def self.command_available?(build_tool)
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
        builder = File.join(path, build_tool)
        if File.exists?(builder)
          return true
        end
      end
      false
    end

    def self.safe_system(*args)
      raise(RuntimeError, "Failed: #{args.join(' ')}") unless system *args
    end
  end
end
