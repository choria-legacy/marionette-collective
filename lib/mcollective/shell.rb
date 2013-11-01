module MCollective
  # Wrapper around systemu that handles executing of system commands
  # in a way that makes stdout, stderr and status available.  Supports
  # timeouts and sets a default sane environment.
  #
  #   s = Shell.new("date", opts)
  #   s.runcommand
  #   puts s.stdout
  #   puts s.stderr
  #   puts s.status.exitstatus
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

      # Check if the parent thread is alive. If it should die,
      # and the process spawned by systemu is still alive,
      # fire off a blocking waitpid and wait for the process to
      # finish so that we can avoid zombies.
      thread = Thread.current
      @status = systemu(@command, opts) do |cid|
        begin
          while(thread.alive?)
            sleep 0.1
          end

          Process.waitpid(cid) if Process.getpgid(cid)
        rescue SystemExit
        rescue Errno::ESRCH
        rescue Errno::ECHILD
        rescue Exception => e
          Log.info("Unexpected exception received while waiting for child process: #{e.class}: #{e}")
        end
      end
      #kill the guardian thread when the process exited
      @status.thread.kill
      @status
    end
  end
end
