#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Log do
    before do
      @logger = mock("logger provider")
      @logger.stubs(:log)
      @logger.stubs(:start)
      @logger.stubs(:set_logging_level)
      @logger.stubs(:valid_levels)
    end

    describe "#cofigure" do
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
      it "should log at debug level" do
        @logger.expects(:log).with(:debug, anything, regexp_matches(/debug test/))
        Log.configure(@logger)
        Log.debug("debug test")
      end

      it "should log at info level" do
        @logger.expects(:log).with(:info, anything, regexp_matches(/info test/))
        Log.configure(@logger)
        Log.info("info test")
      end

      it "should log at fatal level" do
        @logger.expects(:log).with(:fatal, anything, regexp_matches(/fatal test/))
        Log.configure(@logger)
        Log.fatal("fatal test")
      end

      it "should log at error level" do
        @logger.expects(:log).with(:error, anything, regexp_matches(/error test/))
        Log.configure(@logger)
        Log.error("error test")
      end

      it "should log at warning level" do
        @logger.expects(:log).with(:warn, anything, regexp_matches(/warn test/))
        Log.configure(@logger)
        Log.warn("warn test")
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
