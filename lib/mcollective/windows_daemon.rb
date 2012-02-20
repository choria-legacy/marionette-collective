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

      runner = Runner.new(nil)
      runner.run
    end

    def service_stop
      Log.info("Windows service stopping")
      PluginManager["connector_plugin"].disconnect
      exit! 0
    end
  end
end
