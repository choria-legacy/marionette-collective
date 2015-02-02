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
          Util.stubs(:windows?).returns(true)
          WindowsDaemon.expects(:mainloop)
          WindowsDaemon.daemonize_runner
        end
      end

      describe "#service_main" do
        it "should start the runner" do
          runner = mock
          Runner.stubs(:new).returns(runner)
          d = WindowsDaemon.new
          runner.expects(:main_loop)
          d.service_main
        end

        it "should kill any other living threads on exit" do
          d = WindowsDaemon.new
          d.stubs(:running?).returns(false)
          other = mock
          Thread.stubs(:list).returns([Thread.current, other])
          Thread.current.expects(:kill).never
          other.expects(:kill)
          d.service_main
        end
      end

      describe "#service_stop" do
        it "should log, disconnect, stop the runner and exit" do
          runner = mock
          Log.expects(:info)
          d = WindowsDaemon.new
          runner.expects(:stop)
          d.service_stop
        end
      end
    end
  end
end
