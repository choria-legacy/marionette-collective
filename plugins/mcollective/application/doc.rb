module MCollective
  class Application::Doc<Application
    description "Error message help"
    usage "rpc help [ERROR]"

    def post_option_parser(configuration)
      configuration[:query] = ARGV.shift if ARGV.size > 0
    end

    def msg_template
      File.read(Util.templatepath("msg-help.erb"))
    end

    def main
      if configuration[:query] =~ /^PLMC\d+$/i
        msg_code = configuration[:query].upcase
        msg_example = Util.t("%s.example" % msg_code, :raise => true) rescue Util.t("%s.pattern" % msg_code)
        msg_detail = Util.t("%s.expanded" % msg_code)

        helptext = ERB.new(msg_template, 0, '%')
        puts helptext.result(binding)
      end
    end
  end
end
