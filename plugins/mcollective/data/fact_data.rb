module MCollective
  module Data
    class Fact_data<Base
      query do |path|
        parts = path.split /\./
        walk_path(parts)
      end

      private

      def walk_path(path)
        # Set up results as though we didn't find the value
        result[:exists] = false
        result[:value] = false
        result[:value_encoding] = false

        facts = PluginManager['facts_plugin'].get_facts

        path.each do |level|
          case facts
          when Array
            level = Integer(level)
            if level >= facts.size
              # array index out would be out of bounds, so we don't have the value
              return
            end
          when Hash
            if !facts.include?(level)
              # we don't have the key for the next level, so give up
              return
            end
          else
            # this isn't a container data type, so we can't walk into it
            return
          end

          facts = facts[level]
        end

        result[:exists] = true
        case facts
        when Array, Hash
          # Currently data plugins cannot return structured data, so until
          # this is fixed flatten the data with json and flag that we have
          # munged the data
          result[:value] = facts.to_json
          result[:value_encoding] = 'application/json'
        else
          result[:value] = facts
          result[:value_encoding] = 'text/plain'
        end
      end
    end
  end
end
