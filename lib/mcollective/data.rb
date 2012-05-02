module MCollective
  module Data
    autoload :Base, "mcollective/data/base"
    autoload :Result, "mcollective/data/result"

    def self.load_data_sources
      PluginManager.find_and_load("data")

      PluginManager.grep(/_data$/).each do |plugin|
        unless PluginManager[plugin].class.activate?
          Log.debug("Disabling data plugin %s due to plugin activation policy" % plugin)
          PluginManager.delete(plugin)
        end
      end
    end

    def self.[](plugin)
      plugin.to_s =~ /_data$/i ? pluginname = plugin.to_s.downcase : pluginname = "%s_data" % plugin.to_s.downcase

      PluginManager[pluginname]
    end

    # Data.package("httpd").architecture
    def self.method_missing(method, *args)
      method.to_s =~ /_data$/ ? pluginname = method.to_s.downcase : pluginname = "%s_data" % method.to_s.downcase

      super unless PluginManager.include?(pluginname)

      PluginManager[pluginname].lookup(args.first)
    end

    def self.ddl_validate(ddl, argument)
      name = ddl.meta[:name]
      query = ddl.entities[:data]

      raise DDLValidationError, "No dataquery has been defined in the DDL for data plugin #{name}" unless query

      input = query[:input]
      output = query[:output]

      raise DDLValidationError, "No :query input has been defined in the DDL for data plugin #{name}" unless input[:query]
      raise DDLValidationError, "No output has been defined in the DDL for data plugin #{name}" if output.keys.empty?

      ddl.validate_input_argument(input, :query, argument)
    end
  end
end
