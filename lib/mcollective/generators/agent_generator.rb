module MCollective
  module Generators
    class AgentGenerator<Base

      attr_accessor :ddl, :content

      def initialize(plugin_name, actions = [],  name = nil, description = nil, author = nil ,
                     license = nil, version = nil, url = nil, timeout = nil)

        super(name, description, author, license, version, url, timeout)
        @plugin_name = plugin_name
        @actions = actions || []
        @ddl = create_ddl
        @mod_name = "Agent"
        @pclass = "RPC::Agent"
        @content = create_plugin_content
        @plugin = create_plugin_string
        write_plugins
      end

      def create_ddl
        action_text = ""
        @actions.each_with_index do |action, i|
          action_text += "action \"#{action}\", :description => \"%ACTIONDESCRIPTION%\" do\n"
          action_text += action_help if i == 0
          action_text += "end\n"
          action_text += "\n" unless @actions.size == (i + 1)
        end
        # Use inherited method to create metadata part of the ddl
        create_metadata_string + action_text
      end

      def create_plugin_content
        content_text = ""

        # Add actions to agent file
        @actions.each_with_index do |action, i|
          content_text +=  "%6s%s" % [" ", "action \"#{action}\" do\n"]
          content_text +=  "%6s%s" % [" ", "end\n"]
          content_text += "\n" unless @actions.size == (i + 1)
        end
        content_text
      end

      def action_help
        action_snippet = File.read(File.join(File.dirname(__FILE__), "templates", "action_snippet.erb"))
        ERB.new(action_snippet).result
      end
    end
  end
end
