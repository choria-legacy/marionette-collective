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

      it "should write the pid file if requested" do
        f = mock
        f.expects(:write).with(Process.pid)

        File.expects(:open).with("/nonexisting", "w").yields(f)

        r = mock
        r.expects(:run)

        Runner.expects(:new).returns(r)
        UnixDaemon.expects(:daemonize).yields

        UnixDaemon.daemonize_runner("/nonexisting")
      end

      it "should not write a pid file unless requested" do
        r = mock
        r.expects(:run)

        UnixDaemon.expects(:daemonize).yields
        Runner.expects(:new).returns(r)
        File.expects(:open).never

        UnixDaemon.daemonize_runner(nil)
      end
    end
  end
end
