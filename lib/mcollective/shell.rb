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
  #   timeout     - a timeout in seconds after which the subprocess is killed,
  #                 the special value :on_thread_exit kills the subprocess
  #                 when the invoking thread (typically the agent) has ended
  #
  class Shell
    attr_reader :environment, :command, :status, :stdout, :stderr, :stdin, :cwd, :timeout

    def initialize(command, options={})
      @environment = {"LC_ALL" => "C"}
      @command = command
      @status = nil
      @stdout = ""
      @stderr = ""
      @stdin = nil
      @cwd = Dir.tmpdir
      @timeout = nil

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
              @environment = @environment.delete_if { |k,v| v.nil? }
            end

          when "timeout"
            raise "timeout should be a positive integer or the symbol :on_thread_exit symbol" unless val.eql?(:on_thread_exit) || ( val.is_a?(Fixnum) && val>0 )
            @timeout = val
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


      thread = Thread.current
      # Start a double fork and exec with systemu which implies a guard thread.
      # If a valid timeout is configured the guard thread will terminate the
      # executing process and reap the pid.
      # If no timeout is specified the process will run to completion with the
      # guard thread reaping the pid on completion.
      @status = systemu(@command, opts) do |cid|
        begin
          if timeout.is_a?(Fixnum)
            # wait for the specified timeout
            sleep timeout
          else
            # sleep while the agent thread is still alive
            while(thread.alive?)
              sleep 0.1
            end
          end

          # if the process is still running
          if (Process.kill(0, cid))
            # and a timeout was specified
            if timeout
              if Util.windows?
                Process.kill('KILL', cid)
              else
                # Kill the process
                Process.kill('TERM', cid)
                sleep 2
                Process.kill('KILL', cid) if (Process.kill(0, cid))
              end
            end
            # only wait if the parent thread is dead
            Process.waitpid(cid) unless thread.alive?
          end
        rescue SystemExit
        rescue Errno::ESRCH
        rescue Errno::ECHILD
          Log.warn("Could not reap process '#{cid}'.")
        rescue Exception => e
          Log.info("Unexpected exception received while waiting for child process: #{e.class}: #{e}")
        end
      end
      @status.thread.kill
      @status
    end
  end
end
