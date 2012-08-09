module MCollective
  class Application::Completion<MCollective::Application
    description "Helper for shell completion systems"

    exclude_argument_sections "common", "filter", "rpc"

    option :list_agents,
           :description => "List all known agents",
           :arguments => "--list-agents",
           :required => false,
           :type => :boolean

    option :list_actions,
           :description => "List all actions for an agent",
           :arguments => "--list-actions",
           :required => false,
           :type => :boolean

    option :list_inputs,
           :description => "List all inputs for an action",
           :arguments => "--list-inputs",
           :required => false,
           :type => :boolean

    option :list_applications,
           :description => "List all known applications",
           :arguments => "--list-applications",
           :required => false,
           :type => :boolean

    option :agent,
           :description => "The agent to operate on",
           :arguments => "--agent AGENT",
           :required => false

    option :action,
           :description => "The action to operate on",
           :arguments => "--action ACTION",
           :required => false

    def list_agents
      if options[:verbose]
        PluginManager.find(:agent, "ddl").each do |agent|
          begin
            ddl = DDL.new(agent)
            puts "%s:%s" % [ agent, ddl.meta[:description] ]
          rescue
          end
        end
      else
        PluginManager.find(:agent, "ddl").each {|p| puts p}
      end
    end

    def list_actions
      abort "Please specify an agent to list actions for" unless configuration[:agent]

      if options[:verbose]
        ddl = DDL.new(configuration[:agent], :agent)

        ddl.actions.sort.each do |action|
          puts "%s:%s" % [action, ddl.action_interface(action)[:description]]
        end
      else
        DDL.new(configuration[:agent], :agent).actions.sort.each {|a| puts a}
      end
    rescue
    end

    def list_inputs
      abort "Please specify an action and agent to list inputs for" unless configuration[:agent] && configuration[:action]

      if options[:verbose]
        ddl = DDL.new(configuration[:agent], :agent)
        action = ddl.action_interface(configuration[:action])
        action[:input].keys.sort.each do |input|
          puts "%s:%s" % [input, action[:input][input][:description]]
        end
      else
        DDL.new(configuration[:agent], :agent).action_interface(configuration[:action])[:input].keys.sort.each {|i| puts i}
      end
    rescue
    end

    def list_applications
      if options[:verbose]
        Applications.list.each do |app|
          puts "%s:%s" % [app, Applications[app].application_description]
        end
      else
        Applications.list.each {|a| puts a}
      end
    end

    def main
      actions = configuration.keys.map{|k| k.to_s}.grep(/^list_/)

      abort "Please choose either --list-[agents|actions|inputs|applications]" if actions.empty?
      abort "Please choose only one of --list-[agents|actions|inputs|applications]" if actions.size > 1

      send actions.first
    end
  end
end
