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
      @logger.stubs(:new).returns(@logger)

      # we stub it out at the top of the test suite
      Log.unstub(:log)
      Log.unstub(:logexception)
      Log.unstub(:logmsg)

      Log.set_logger(@logger)
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
        [:debug, :info, :fatal, :error, :warn].each do |level|
          @logger.expects(:log).with(level, anything, regexp_matches(/#{level} test/))
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

    describe "#from" do
      let(:execution_stack) do
        if Util.windows?
          ['C:\rspec\test1:52:in `rspec block1\'',
           'C:\rspec\test2:52:in `rspec block2\'',
           'C:\rspec\test3:52:in `rspec block3\'',
           'C:\rspec\test4:52:in `rspec block4\'']
        else
          ["/rspec/test1:52:in `rspec block1'",
           "/rspec/test2:52:in `rspec block2'",
           "/rspec/test3:52:in `rspec block3'",
           "/rspec/test4:52:in `rspec block4'"]
        end
      end

      it "should return the correct from string when given file, line, block" do
        Log.stubs(:execution_stack).returns(execution_stack)
        Log.from.should == "test4:52:in `rspec block4'"
      end

      it "should return the correct from string shen given file and line" do
        if Util.windows?
          execution_stack[3] = 'C:\rspec\test4:52'
        else
          execution_stack[3] = '/rspec/test4:52'
        end

        Log.stubs(:execution_stack).returns(execution_stack)
        Log.from.should == "test4:52"
      end
    end
  end
end
