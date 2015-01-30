#!/usr/bin/env rspec

require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/security/psk.rb'

module MCollective::Security
  describe Psk do
    before do
      @config = mock("config")
      @config.stubs(:identity).returns("test")
      @config.stubs(:configured).returns(true)
      @config.stubs(:pluginconf).returns({"psk" => "12345"})

      @stats = mock("stats")

      @time = Time.now.to_i
      ::Time.stubs(:now).returns(@time)

      MCollective::Log.stubs(:debug).returns(true)

      MCollective::PluginManager << {:type => "global_stats", :class => @stats}
      MCollective::Config.stubs("instance").returns(@config)
      MCollective::Util.stubs("empty_filter?").returns(false)

      @plugin = Psk.new
    end

    describe "#decodemsg" do
      it "should correctly decode a message" do
        @plugin.stubs("validrequest?").returns(true).once

        msg = mock("message")
        msg.stubs(:payload).returns(Marshal.dump({:body => Marshal.dump("foo")}))
        msg.stubs(:expected_msgid).returns(nil)

        @plugin.decodemsg(msg).should == {:body=>"foo"}
      end

      it "should return nil on failure" do
        @plugin.stubs("validrequest?").raises("fail").once

        msg = mock("message")
        msg.stubs(:payload).returns(Marshal.dump({:body => Marshal.dump("foo"), :requestid => "123"}))
        msg.stubs(:expected_msgid).returns(nil)

        expect { @plugin.decodemsg(msg) }.to raise_error("fail")
      end

      it "should not decode messages not addressed to us" do
        msg = mock("message")
        msg.stubs(:payload).returns(Marshal.dump({:body => Marshal.dump("foo"), :requestid => "456"}))
        msg.stubs(:expected_msgid).returns("123")

        expect {
          @plugin.decodemsg(msg)
        }.to raise_error("Got a message with id 456 but was expecting 123, ignoring message")

      end

      it "should only decode messages addressed to us" do
        @plugin.stubs("validrequest?").returns(true).once

        msg = mock("message")
        msg.stubs(:payload).returns(Marshal.dump({:body => Marshal.dump("foo"), :requestid => "456"}))
        msg.stubs(:expected_msgid).returns("456")

        @plugin.decodemsg(msg).should == {:body=>"foo", :requestid=>"456"}
      end
    end

    describe "#encodereply" do
      it "should correctly Marshal encode the reply" do
        @plugin.stubs("create_reply").returns({:test => "test"})
        Marshal.stubs("dump").with("test message").returns("marshal_test_message").once
        Marshal.stubs("dump").with({:hash => '2dbeb0d7938a08a34eacd2c1dab25602', :test => 'test'}).returns("marshal_test_reply").once

        @plugin.encodereply("sender", "test message", "requestid", "callerid").should == "marshal_test_reply"
      end
    end

    describe "#encoderequest" do
      it "should correctly Marshal encode the request" do
        @plugin.stubs("create_request").returns({:test => "test"})
        Marshal.stubs("dump").with("test message").returns("marshal_test_message").once
        Marshal.stubs("dump").with({:hash => '2dbeb0d7938a08a34eacd2c1dab25602', :test => 'test'}).returns("marshal_test_request").once

        @plugin.encoderequest("sender", "test message", "requestid", "filter", "agent", "collective").should == "marshal_test_request"
      end
    end

    describe "#validrequest?" do
      it "should correctly validate requests" do
        @stats.stubs(:validated).once
        @stats.stubs(:unvalidated).never
        @plugin.validrequest?({:body => "foo", :hash => "e83ac78027b77b659a49bccbbcfa4849"})
      end

      it "should raise an exception on failure" do
        @stats.stubs(:validated).never
        @stats.stubs(:unvalidated).once
        expect { @plugin.validrequest?({:body => "foo", :hash => ""}) }.to raise_error("Received an invalid signature in message")
      end
    end

    describe "#callerid" do
      it "should do uid based callerid when unconfigured" do
        @plugin.callerid.should == "uid=#{Process.uid}"
      end

      it "should support gid based callerids" do
        @config.stubs(:pluginconf).returns({"psk.callertype" => "gid"})
        @plugin.callerid.should == "gid=#{Process.gid}"
      end

      it "should support group based callerids", :unless => MCollective::Util.windows? do
        @config.stubs(:pluginconf).returns({"psk.callertype" => "group"})
        @plugin.callerid.should == "group=#{Etc.getgrgid(Process.gid).name}"
      end

      it "should raise an error if the group callerid type is used on windows" do
        MCollective::Util.expects("windows?").returns(true)
        @config.stubs(:pluginconf).returns({"psk.callertype" => "group"})
        expect { @plugin.callerid }.to raise_error("Cannot use the 'group' callertype for the PSK security plugin on the Windows platform")
      end

      it "should support user based callerids" do
        @config.stubs(:pluginconf).returns({"psk.callertype" => "user"})
        @plugin.callerid.should == "user=#{Etc.getlogin}"
      end

      it "should support identity based callerids" do
        @config.stubs(:pluginconf).returns({"psk.callertype" => "identity"})
        @plugin.callerid.should == "identity=test"
      end
    end

    describe "#makehash" do
      it "should return the correct md5 digest" do
        @plugin.send(:makehash, "foo").should == "e83ac78027b77b659a49bccbbcfa4849"
      end

      it "should fail if no PSK is configured" do
        @config.stubs(:pluginconf).returns({})
        expect { @plugin.send(:makehash, "foo") }.to raise_error("No plugin.psk configuration option specified")
      end

      it "should support reading the PSK from the environment" do
        ENV["MCOLLECTIVE_PSK"] = "54321"

        @plugin.send(:makehash, "foo").should == "d3fb63cc6b1d47cc4b2012df926c2feb"

        ENV.delete("MCOLLECTIVE_PSK")
      end
    end
  end
end
