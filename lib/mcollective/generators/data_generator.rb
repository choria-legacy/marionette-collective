module MCollective
  module Generators
    class DataGenerator<Base

      attr_accessor :ddl, :content

      def initialize(plugin_name, outputs = [],  name = nil, description = nil, author = nil ,
                     license = nil, version = nil, url = nil, timeout = nil)

        super(name, description, author, license, version, url, timeout)
        @mod_name = "Data"
        @pclass = "Base"
        @plugin_name = plugin_name
        @outputs = outputs
        @ddl = create_ddl
        @content = create_plugin_content
        @plugin = create_plugin_string
        write_plugins
      end

      def create_ddl
        query_text = "dataquery :description => \"Query information\" do\n"
        query_text += ERB.new(File.read(File.join(File.dirname(__FILE__), "templates", "data_input_snippet.erb"))).result

        @outputs.each_with_index do |output,i|
          query_text += "%2s%s" % [" ", "output :#{output},\n"]
          query_text += "%9s%s" % [" ", ":description => \"%DESCRIPTION%\",\n"]
          query_text += "%9s%s" % [" ", ":display_as => \"%DESCRIPTION%\"\n"]
          query_text += "\n" unless @outputs.size == (i + 1)
        end

        query_text += "end"

        # Use inherited method to create metadata part of the ddl
        create_metadata_string + query_text
      end

      def create_plugin_content
        content_text = "%6s%s" % [" ", "query do |what|\n"]

        @outputs.each do |output|
           content_text += "%8s%s" % [" ", "result[:#{output}] = nil\n"]
        end
        content_text += "%6s%s" % [" ", "end\n"]

        # Add actions to agent file
        content_text
      end
    end
  end
end
