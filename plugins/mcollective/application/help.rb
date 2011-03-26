module MCollective
    class Application::Help<Application
        description "Application list and RPC agent help"
        usage "rpc help [agent name]"

        def post_option_parser(configuration)
            configuration[:agent] = ARGV.shift if ARGV.size > 0
        end

        def main
            if configuration.include?(:agent)
                ddl = MCollective::RPC::DDL.new(configuration[:agent])
                puts ddl.help(Config.instance.rpchelptemplate)
            else
                puts "The Marionette Collective version #{MCollective.version}"
                puts

                Applications.list.sort.each do |app|
                    puts "  %-15s %s" % [app, Applications[app].application_description]
                end

                puts
            end
        end
    end
end
