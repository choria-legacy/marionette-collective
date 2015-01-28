module MCollective
  module Data
    require "mcollective/data/base"
    require "mcollective/data/result"

    def self.load_data_sources
      PluginManager.find_and_load("data")

      PluginManager.grep(/_data$/).each do |plugin|
        begin
          unless PluginManager[plugin].class.activate?
            Log.debug("Disabling data plugin %s due to plugin activation policy" % plugin)
            PluginManager.delete(plugin)
          end
        rescue Exception => e
          Log.debug("Disabling data plugin %s due to exception #{e.class}: #{e}" % plugin)
          PluginManager.delete(plugin)
        end
      end
    end

    def self.pluginname(plugin)
      plugin.to_s =~ /_data$/i ? plugin.to_s.downcase : "%s_data" % plugin.to_s.downcase
    end

    def self.[](plugin)
      PluginManager[pluginname(plugin)]
    end

    # Data.package("httpd").architecture
    def self.method_missing(method, *args)
      super unless PluginManager.include?(pluginname(method))

      PluginManager[pluginname(method)].lookup(args.first)
    end

    def self.ddl(plugin)
      DDL.new(pluginname(plugin), :data)
    end

    def self.ddl_validate(ddl, argument)
      name = ddl.meta[:name]
      query = ddl.entities[:data]

      raise DDLValidationError, "No dataquery has been defined in the DDL for data plugin #{name}" unless query

      input = query.fetch(:input, {})
      output = query.fetch(:output, {})

      raise DDLValidationError, "No output has been defined in the DDL for data plugin #{name}" if output.keys.empty?

      if input[:query]
        return true if argument.nil? && input[:query][:optional]

        ddl.validate_input_argument(input, :query, argument)
      else
        raise("No data plugin argument was declared in the %s DDL but an input was supplied" % name) if argument
        return true
      end
    end

    def self.ddl_has_output?(ddl, output)
      ddl.entities[:data][:output].include?(output.to_sym) rescue false
    end

    # For an input where the DDL requests a boolean or some number
    # this will convert the input to the right type where possible
    # else just returns the origin input unedited
    #
    # if anything here goes wrong just return the input value
    # this is not really the end of the world or anything since
    # all that will happen is that DDL validation will fail and
    # the user will get an error, no need to be too defensive here
    def self.ddl_transform_input(ddl, input)
      begin
        type = ddl.entities[:data][:input][:query][:type]

        case type
          when :boolean
            return DDL.string_to_boolean(input)

          when :number, :integer, :float
            return DDL.string_to_number(input)
        end
      rescue
      end

      return input
    end
  end
end
