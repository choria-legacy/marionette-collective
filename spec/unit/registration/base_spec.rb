#!/usr/bin/env rspec

require 'spec_helper'

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
          @reg.publish(nil)
        end

        it "should publish via the message object" do
          message = mock
          message.expects(:encode!)
          message.expects(:publish)
          message.expects(:requestid).returns("123")
          message.expects(:collective).returns("mcollective")

          Message.expects(:new).returns(message)

          Log.expects(:debug).with("Sending registration 123 to collective mcollective")

          @reg.expects(:target_collective).returns("mcollective")

          @reg.publish("message")
        end
      end
    end
  end
end
