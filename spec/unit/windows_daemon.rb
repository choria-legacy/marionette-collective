#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  if Util.windows?
    require 'mcollective/windows_daemon'

    describe WindowsDaemon do
      describe "#daemonize_runner" do
        it "should only run on the windows platform" do
          Util.expects("windows?").returns(false)
          expect { WindowsDaemon.daemonize_runner }.to raise_error("The Windows Daemonizer should only be used on the Windows Platform")
        end

        it "should not support writing pid files" do
          expect { WindowsDaemon.daemonize_runner(true) }.to raise_error("Writing pid files are not supported on the Windows Platform")
        end

        it "should start the mainloop" do
          WindowsDaemon.expects(:mainloop)
          WindowsDaemon.daemonize_runner
        end
      end

      describe "#service_stop" do
        it "should disconnect and exit" do
          Log.expects(:info)

          connector = mock
          connector.expects(:disconnect).once

          PluginManager.expects("[]").with("connector_plugin").returns(connector)

          d = WindowsDaemon.new
          d.expects("exit!").once

          d.service_stop
        end
      end
    end
  end
end
