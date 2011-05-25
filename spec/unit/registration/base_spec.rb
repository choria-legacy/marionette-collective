#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

module MCollective
    module Registration
        describe Base do
            before do
                @config = mock
                @config.stubs(:identity).returns("rspec")
                @config.stubs(:main_collective).returns("main_collective")
                Config.stubs(:instance).returns(@config)

                @reg = Base.new
            end

            describe "#config" do
                it "should provide access the main configuration class" do
                    @reg.config.should == @config
                end

            end

            describe "#identity" do
                it "should return the correct identity" do
                    @reg.config.identity.should == "rspec"
                end
            end

            describe "#msg_filter" do
                it "should target the registration agent" do
                    @reg.msg_filter.should == {"agent" => "registration"}
                end
            end

            describe "#msg_id" do
                it "should create the message id correctly" do
                    Digest::MD5.expects(:hexdigest).with(regexp_matches(/rspec-.+-test/))
                    @reg.msg_id("test")
                end
            end

            describe "#msg_target" do
                it "should create a target for the correct agent and collective" do
                    @reg.expects(:target_collective).returns("test").once
                    Util.expects(:make_target).with("registration", :command, "test").once
                    @reg.msg_target
                end
            end

            describe "#target_collective" do
                it "should return the configured registration_collective" do
                    @config.expects(:registration_collective).returns("registration").once
                    @config.expects(:collectives).returns(["main_collective", "registration"]).once
                    @reg.target_collective.should == "registration"
                end

                it "should use the main collective if registration collective is not valid" do
                    @config.expects(:registration_collective).returns("registration").once
                    @config.expects(:collectives).returns(["main_collective"]).once

                    Log.expects(:warn).with("Sending registration to main_collective: registration is not a valid collective").once

                    @reg.target_collective.should == "main_collective"
                end
            end

            describe "#publish" do
                it "should skip registration for empty messages" do
                    Log.expects(:debug).with("Skipping registration due to nil body")
                    @reg.publish(nil, nil)
                end

                it "should encode the request via the security plugin and publish correctly" do
                    security_plugin = mock
                    connection = mock

                    PluginManager.expects("[]").with("security_plugin").returns(security_plugin)

                    @reg.expects(:msg_target).returns("target").once
                    @reg.expects(:msg_id).with("target").returns("msgid").once
                    @reg.expects(:msg_filter).returns("msgfilter").once

                    security_plugin.expects(:encoderequest).with("rspec", "target", "message", "msgid", "msgfilter").returns("req").once
                    connection.expects(:publish).with("target", "req")
                    Log.expects(:debug).with("Sending registration msgid to target")

                    @reg.publish("message", connection)
                end
            end
        end
    end
end
