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
      while running?
        return if state != RUNNING
        @runner = Runner.new(nil)
        @runner.run
      end

      # Right now we don't have a way to let the connection and windows sleeper threads
      # run to conclusion. Until that is possible we iterate the list of living threads
      # and kill everything that isn't the main thread. This lets us exit cleanly.
      Thread.list.each do |t|
        if t != Thread.current
          t.kill
        end
      end
    end

    def service_stop
      Log.info("Windows service stopping")
      @runner.stop
      PluginManager["connector_plugin"].disconnect
    end
  end
end
