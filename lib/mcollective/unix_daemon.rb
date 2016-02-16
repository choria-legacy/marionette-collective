module MCollective
  class UnixDaemon
    # Daemonize the current process
    def self.daemonize
      fork do
        Process.setsid
        exit if fork
        Dir.chdir('/tmp')
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen('/dev/null', 'a')

        yield
      end
    end

    def self.daemonize_runner(pid=nil)
      raise "The Unix Daemonizer can not be used on the Windows Platform" if Util.windows?

      UnixDaemon.daemonize do
        if pid
          # Clean up stale pidfile if needed
          if File.exist?(pid)
            lock_pid = File.read(pid)
            begin
              lock_pid = Integer(lock_pid)
            rescue ArgumentError, TypeError
              lock_pid = nil
            end

            # If there's no pid in the pidfile, remove it
            if lock_pid.nil?
              File.unlink(pid)
            else
              begin
                # This will raise an error if the process doesn't
                # exist, and do nothing otherwise
                Process.kill(0, lock_pid)
                # If we reach this point then the process is running.
                # We should raise an error rather than continuing on
                # trying to create the PID
                raise "Process is already running with PID #{lock_pid}"
              rescue Errno::ESRCH
                # Errno::ESRCH = no such process
                # PID in pidfile doesn't exist, remove pidfile
                File.unlink(pid)
              end
            end

          end

          # Use exclusive create on the PID to avoid race condition
          # when two mcollectived processes start at the same time
          opt =  File::CREAT | File::EXCL | File::WRONLY
          File.open(pid, opt) {|f| f.print(Process.pid) }
        end

        begin
          runner = Runner.new(nil)
          runner.main_loop
        rescue => e
          Log.warn(e.backtrace)
          Log.warn(e)
        ensure
          File.unlink(pid) if pid && File.exist?(pid)
        end
      end
    end
  end
end
