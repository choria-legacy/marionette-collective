#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Log do
    before do
      @logger = mock("logger provider")
      @logger.stubs(:start)
      @logger.stubs(:set_logging_level)
      @logger.stubs(:valid_levels)
      @logger.stubs(:should_log?).returns(true)
      @logger.stubs(:new).returns(@logger)

      # we stub it out at the top of the test suite
      Log.unstub(:log)
      Log.unstub(:logexception)
      Log.unstub(:logmsg)

      Log.unconfigure
      Log.set_logger(@logger)
    end

    describe "#config_and_check_level" do
      it "should configure then not already configured" do
        Log.expects(:configure)
        Log.config_and_check_level(:debug)
      end

      it "should not reconfigure the logger" do
        Log.configure(@logger)
        Log.expects(:configure).never
        Log.config_and_check_level(:debug)
      end

      it "should check the level is valid" do
        Log.configure(@logger)
        Log.expects(:check_level).with(:debug)
        Log.config_and_check_level(:debug)
      end

      it "should respect the loggers decision about levels" do
        Log.configure(@logger)
        @logger.expects(:should_log?).returns(false)
        Log.config_and_check_level(:debug).should == false
      end
    end

    describe "#valid_level?" do
      it "should correctly report for valid levels" do
        [:error, :fatal, :debug, :warn, :info].each {|level| Log.valid_level?(level).should == true }
        Log.valid_level?(:rspec).should == false
      end
    end

    describe "#message_for" do
      it "should return the code and retrieved message" do
        Util.expects(:t).with(:PLMC1, {:rspec => true}).returns("this is PLMC1")
        Log.message_for(:PLMC1, {:rspec => true}).should == "PLMC1: this is PLMC1"
      end
    end

    describe "#logexception" do
      it "should short circuit messages below current level" do
        Log.expects(:config_and_check_level).with(:debug).returns(false)
        Log.expects(:log).never
        Log.logexception(:PLMC1, :debug, Exception.new, {})
      end

      it "should request the message including the exception string and log it" do
        pending("#20506", :if => MCollective::Util.windows?) do
        Log.stubs(:config_and_check_level).returns(true)
        Log.expects(:message_for).with(:PLMC1, {:rspec => "test", :error => "Exception: this is a test"}).returns("This is a test")
        Log.expects(:log).with(:debug, "This is a test", "test:2")

        e = Exception.new("this is a test")
        e.set_backtrace ["/some/dir/test:1", "/some/dir/test:2"]

        Log.logexception(:PLMC1, :debug, e, false, {:rspec => "test"})
        end
      end
    end

    describe "#logmsg" do
      it "should short circuit messages below current level" do
        Log.expects(:config_and_check_level).with(:debug).returns(false)
        Log.expects(:log).never
        Log.logmsg(:PLMC1, "", :debug, {})
      end

      it "should request the message and log it" do
        Log.stubs(:config_and_check_level).returns(true)
        Log.expects(:message_for).with(:PLMC1, {:rspec => "test", :default => "default"}).returns("This is a test")
        Log.expects(:log).with(:debug, "This is a test")
        Log.logmsg(:PLMC1, "default", :debug, :rspec => "test")
      end
    end

    describe "#check_level" do
      it "should check for valid levels" do
        Log.expects(:valid_level?).with(:debug).returns(true)
        Log.check_level(:debug)
      end

      it "should raise for invalid levels" do
        expect { Log.check_level(:rspec) }.to raise_error("Unknown log level")
      end
    end

    describe "#configure" do
      it "should default to console logging if called prior to configuration" do
        Config.instance.instance_variable_set("@configured", false)
        Log.configure
        Log.logger.should ==  MCollective::Logger::Console_logger
      end
    end

    describe "#instance" do
      it "should return the correct reference" do
        Log.configure(@logger)
        Log.instance.should == MCollective::Log
      end
    end

    describe "#log" do
      it "should log at the right levels" do
        Log.configure(@logger)

        [:debug, :info, :fatal, :error, :warn].each do |level|
          @logger.expects(:log).with(level, anything, regexp_matches(/#{level} test/))
          @logger.expects(:should_log?).with(level).returns(true)
          Log.send(level, "#{level} test")
        end
      end
    end

    describe "#cycle_level" do
      it "should cycle logger class levels" do
        @logger.expects(:cycle_level)

        Log.configure(@logger)
        Log.cycle_level
      end
    end
  end
end
