module MCollective
  # Wrapper around systemu that handles executing of system commands
  # in a way that makes stdout, stderr and status available.  Supports
  # timeouts and sets a default sane environment.
  #
  #   s = Shell.new("date", opts)
  #   s.runcommand
  #   puts s.stdout
  #   puts s.stderr
  #   puts s.status.exitcode
  #
  # Options hash can have:
  #
  #   cwd         - the working directory the command will be run from
  #   stdin       - a string that will be sent to stdin of the program
  #   stdout      - a variable that will receive stdout, must support <<
  #   stderr      - a variable that will receive stdin, must support <<
  #   environment - the shell environment, defaults to include LC_ALL=C
  #                 set to nil to clear the environment even of LC_ALL
  #
  class Shell
    attr_reader :environment, :command, :status, :stdout, :stderr, :stdin, :cwd

    def initialize(command, options={})
      @environment = {"LC_ALL" => "C"}
      @command = command
      @status = nil
      @stdout = ""
      @stderr = ""
      @stdin = nil
      @cwd = Dir.tmpdir

      options.each do |opt, val|
        case opt.to_s
          when "stdout"
            raise "stdout should support <<" unless val.respond_to?("<<")
            @stdout = val

          when "stderr"
            raise "stderr should support <<" unless val.respond_to?("<<")
            @stderr = val

          when "stdin"
            raise "stdin should be a String" unless val.is_a?(String)
            @stdin = val

          when "cwd"
            raise "Directory #{val} does not exist" unless File.directory?(val)
            @cwd = val

          when "environment"
            if val.nil?
              @environment = {}
            else
              @environment.merge!(val.dup)
            end
        end
      end
    end

    # Actually does the systemu call passing in the correct environment, stdout and stderr
    def runcommand
      opts = {"env"    => @environment,
              "stdout" => @stdout,
              "stderr" => @stderr,
              "cwd"    => @cwd}

      opts["stdin"] = @stdin if @stdin

      # Running waitpid on the cid here will start a thread
      # with the waitpid in it, this way even if the thread
      # that started this process gets killed due to agent
      # timeout or such there will still be a waitpid waiting
      # for the child to exit and not leave zombies.
      @status = systemu(@command, opts) do |cid|
        begin
          sleep 1
          Process::waitpid(cid)
        rescue SystemExit
        rescue Errno::ECHILD
        rescue Exception => e
          Log.info("Unexpected exception received while waiting for child process: #{e.class}: #{e}")
        end
      end
    end
  end
end
