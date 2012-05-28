module MCollective
  class Applications
    def self.[](appname)
      load_application(appname)
      PluginManager["#{appname}_application"]
    end

    def self.run(appname)
      load_config

      begin
        load_application(appname)
      rescue Exception => e
        e.backtrace.first << Util.colorize(:red, "  <----")
        STDERR.puts "Application '#{appname}' failed to load:"
        STDERR.puts
        STDERR.puts Util.colorize(:red, "   #{e} (#{e.class})")
        STDERR.puts
        STDERR.puts "       %s" % [e.backtrace.join("\n       ")]
        exit 1
      end

      PluginManager["#{appname}_application"].run
    end

    def self.load_application(appname)
      return if PluginManager.include?("#{appname}_application")

      load_config

      PluginManager.loadclass "MCollective::Application::#{appname.capitalize}"
      PluginManager << {:type => "#{appname}_application", :class => "MCollective::Application::#{appname.capitalize}"}
    end

    # Returns an array of applications found in the lib dirs
    def self.list
      load_config

      PluginManager.find("application")
    rescue SystemExit
      exit 1
    rescue Exception => e
      STDERR.puts "Failed to generate application list: #{e.class}: #{e}"
      exit 1
    end

    # Filters a string of opts out using Shellwords
    # keeping only things related to --config and -c
    def self.filter_extra_options(opts)
      res = ""
      words = Shellwords.shellwords(opts)
      words.each_with_index do |word,idx|
        if word == "-c"
          return "--config=#{words[idx + 1]}"
        elsif word == "--config"
          return "--config=#{words[idx + 1]}"
        elsif word =~ /\-c=/
          return word
        elsif word =~ /\-\-config=/
          return word
        end
      end

      return ""
    end

    # We need to know the config file in order to know the libdir
    # so that we can find applications.
    #
    # The problem is the CLI might be stuffed with options only the
    # app in the libdir might understand so we have a chicken and
    # egg situation.
    #
    # We're parsing and filtering MCOLLECTIVE_EXTRA_OPTS removing
    # all but config related options and parsing the options looking
    # just for the config file.
    #
    # We're handling failures gracefully and finally restoring the
    # ARG and MCOLLECTIVE_EXTRA_OPTS to the state they were before
    # we started parsing.
    #
    # This is mostly a hack, when we're redoing how config works
    # this stuff should be made less sucky
    def self.load_config
      return if Config.instance.configured

      original_argv = ARGV.clone
      original_extra_opts = ENV["MCOLLECTIVE_EXTRA_OPTS"].clone rescue nil
      configfile = nil

      parser = OptionParser.new
      parser.on("--config CONFIG", "-c", "Config file") do |f|
        configfile = f
      end

      parser.program_name = $0

      parser.on("--help")

      # avoid option parsers own internal version handling that sux
      parser.on("-v", "--verbose")

      if original_extra_opts
        begin
          # optparse will parse the whole ENV in one go and refuse
          # to play along with the retry trick I do below so in
          # order to handle unknown options properly I parse out
          # only -c and --config deleting everything else and
          # then restore the environment variable later when I
          # am done with it
          ENV["MCOLLECTIVE_EXTRA_OPTS"] = filter_extra_options(ENV["MCOLLECTIVE_EXTRA_OPTS"].clone)
          parser.environment("MCOLLECTIVE_EXTRA_OPTS")
        rescue Exception => e
          Log.error("Failed to parse MCOLLECTIVE_EXTRA_OPTS: #{e}")
        end

        ENV["MCOLLECTIVE_EXTRA_OPTS"] = original_extra_opts.clone
      end

      begin
        parser.parse!
      rescue OptionParser::InvalidOption => e
        retry
      end

      ARGV.clear
      original_argv.each {|a| ARGV << a}

      configfile = Util.config_file_for_user unless configfile

      Config.instance.loadconfig(configfile)
    end
  end
end
