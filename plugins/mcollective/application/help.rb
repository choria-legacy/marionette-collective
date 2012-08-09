module MCollective
  class Application::Help<Application
    description "Application list and help"
    usage "rpc help [application name]"

    def post_option_parser(configuration)
      configuration[:application] = ARGV.shift if ARGV.size > 0
    end

    def main
      if configuration.include?(:application)
        puts Applications[configuration[:application]].help
      else
        puts "The Marionette Collective version #{MCollective.version}"
        puts

        Applications.list.sort.each do |app|
          begin
            puts "  %-15s %s" % [app, Applications[app].application_description]
          rescue
          end
        end

        puts
      end
    end
  end
end
