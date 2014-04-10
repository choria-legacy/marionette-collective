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
          begin
            File.open(pid, 'w') {|f| f.write(Process.pid) }
          rescue Exception => e
          end
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
