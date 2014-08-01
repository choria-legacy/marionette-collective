#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Registration
    describe Base do

      let(:connection) { mock }

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

      describe "#run" do
        it "should not start the publish_thread if the registration interval is 0" do
          @reg.stubs(:interval).returns(0)
          Thread.expects(:new).never
          @reg.run(connection).should == false
        end

        it "should start the publish_thread" do
          @reg.stubs(:interval).returns(1)
          Thread.expects(:new).returns(true)
          @reg.run(connection).should be_true
        end
      end

      describe "#identity" do
        it "should return the correct identity" do
          @reg.config.identity.should == "rspec"
        end
      end

      describe "#msg_filter" do
        it "should target the registration agent" do
          @reg.msg_filter["agent"].should == ["registration"]
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

      describe "#body" do
        it "should fail if body hasn't been implemented" do
          expect {
            @reg.body
          }.to raise_error
        end
      end

      describe "#publish_thread" do
        before(:each) do
          @reg.expects(:loop).returns("looping")
        end

        it "should splay if splay is set" do
          @reg.stubs(:interval).returns(1)
          @config.stubs(:registration_splay).returns(true)
          Log.expects(:debug)
          @reg.expects(:sleep)
          @reg.send(:publish_thread, connection)
        end

        it "should not splay if splay isn't set" do
          @reg.stubs(:interval).returns(1)
          @config.stubs(:registration_splay).returns(false)
          Log.expects(:debug).never
          @reg.expects(:sleep).never
          @reg.send(:publish_thread, connection)
        end
      end
    end
  end
end
