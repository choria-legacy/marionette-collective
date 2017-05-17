#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/audit/logfile'

module MCollective
  module RPC
    describe Logfile do
      let(:file) do
        mock
      end

      let(:request) do
        req = mock
        req.stubs(:uniqid).returns("1234")
        req.stubs(:time).returns(1389179593)
        req.stubs(:caller).returns("test_user")
        req.stubs(:sender).returns("test_host")
        req.stubs(:agent).returns("rspec_agent")
        req.stubs(:action).returns("testme")
        req.stubs(:data).returns({})
        req
      end

      before :each do
        Time.stubs(:now).returns(Time.at(1389180255))
        file.expects(:puts).with("[2014-01-08 11:24:15 UTC] reqid=1234: reqtime=1389179593 caller=test_user@test_host " +
                                  "agent=rspec_agent action=testme data={}")
      end

      it 'should log to a user defined logfile' do
        Config.any_instance.stubs(:pluginconf).returns("rpcaudit.logfile" => "/nonexisting")
        File.expects(:open).with("/nonexisting", "a").yields(file)
        Logfile.new.audit_request(request, nil)
      end

      it 'should log to a default logfile' do
        Config.any_instance.stubs(:pluginconf).returns({})
        File.expects(:open).with("/var/log/puppetlabs/mcollective/mcollective-audit.log", "a").yields(file)
        Logfile.new.audit_request(request, nil)
      end
    end
  end
end
