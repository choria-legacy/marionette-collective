require 'win32/daemon'

module MCollective
  class WindowsDaemon < Win32::Daemon

    def self.daemonize_runner(pid=nil)
      raise "Writing pid files are not supported on the Windows Platform" if pid
      raise "The Windows Daemonizer should only be used on the Windows Platform" unless Util.windows?

      WindowsDaemon.mainloop
    end

    def service_main
      Log.debug("Starting Windows Service Daemon")

      @runner = Runner.new(nil)
      @runner.main_loop

      # On shut down there may be threads outside of the runner's context that are
      # in a sleeping state, causing the stop action to wait for them to cleanly exit.
      # We get around this by iterating the list of threads and killing everything that
      # isn't the main thread, letting us shut down cleanly.
      Thread.list.each do |t|
        if t != Thread.current
          t.kill
        end
      end
    end

    def service_stop
      Log.info("Windows service stopping")
      @runner.stop
    end

    def service_pause
      Log.info("Pausing MCollective Windows server")
      @runner.pause
    end

    def service_resume
      Log.info("Resuming MCollective Windows server")
      @runner.resume
    end
  end
end
