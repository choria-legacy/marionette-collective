#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/unix_daemon'

module MCollective
  describe UnixDaemon do
    describe "#daemonize_runner" do
      it "should not run on the windows platform" do
        Util.expects("windows?").returns(true)
        expect { UnixDaemon.daemonize_runner }.to raise_error("The Unix Daemonizer can not be used on the Windows Platform")
      end

      it "should write the pid file if requested", :unless => MCollective::Util.windows? do
        f = mock
        f.expects(:print).with(Process.pid)

        File.expects(:open).with("/nonexisting", File::CREAT | File::EXCL | File::WRONLY).yields(f)

        r = mock
        r.expects(:main_loop)

        Runner.expects(:new).returns(r)
        UnixDaemon.expects(:daemonize).yields

        UnixDaemon.daemonize_runner("/nonexisting")
      end

      it "should clean a stale pid file", :unless => MCollective::Util.windows? do
        f = mock
        f.expects(:print).with(Process.pid)

        File.expects(:exist?).with("/nonexisting").twice.returns(true).then.returns(false)
        File.expects(:read).with("/nonexisting").returns '1234'
        File.expects(:unlink).with("/nonexisting")
        Process.expects(:kill).with(0, 1234).raises(Errno::ESRCH)
        File.expects(:open).with("/nonexisting", File::CREAT | File::EXCL | File::WRONLY).yields(f).returns true

        r = mock
        r.expects(:main_loop)
        Runner.expects(:new).returns(r)
        UnixDaemon.expects(:daemonize).yields
        UnixDaemon.daemonize_runner("/nonexisting")
      end

      it "should not write a pid file if the process is running", :unless => MCollective::Util.windows? do
        File.expects(:exist?).with("/nonexisting").returns true
        File.expects(:read).with("/nonexisting").returns '1234'
        Process.expects(:kill).with(0, 1234).returns true
        File.expects(:open).never

        UnixDaemon.expects(:daemonize).yields
        expect { UnixDaemon.daemonize_runner("/nonexisting") }.to raise_error "Process is already running with PID 1234"
      end

      it "should clean an empty pid file", :unless => MCollective::Util.windows? do
        f = mock
        f.expects(:print).with(Process.pid)

        File.expects(:exist?).with("/nonexisting").twice.returns(true).then.returns(false)
        File.expects(:read).with("/nonexisting").returns ''

        File.expects(:unlink).with("/nonexisting")
        File.expects(:open).with("/nonexisting", File::CREAT | File::EXCL | File::WRONLY).yields(f).returns true

        r = mock
        r.expects(:main_loop)
        Runner.expects(:new).returns(r)
        UnixDaemon.expects(:daemonize).yields
        UnixDaemon.daemonize_runner("/nonexisting")
      end

      it "should not write a pid file unless requested", :unless => MCollective::Util.windows? do
        r = mock
        r.expects(:main_loop)

        UnixDaemon.expects(:daemonize).yields
        Runner.expects(:new).returns(r)
        File.expects(:open).never

        UnixDaemon.daemonize_runner(nil)
      end
    end
  end
end
