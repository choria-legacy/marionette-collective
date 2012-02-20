#!/usr/bin/env rspec

require 'spec_helper'

module MCollective::Logger
  describe Base do
    before do
      Base.any_instance.stubs(:set_logging_level).returns(true)
      Base.any_instance.stubs(:valid_levels).returns({:info  => :info_test,
                                                       :warn  => :warning_test,
                                                       :debug => :debug_test,
                                                       :fatal => :crit_test,
                                                       :error => :err_test})
    end

    describe "#initialize" do
      it "should check for valid levels" do
        Base.any_instance.stubs(:valid_levels).returns({})

        expect {
          Base.new
        }.to raise_error(/Logger class did not specify a map for/)
      end

      it "should accept correct levels" do
        Base.new
      end
    end

    describe "#valid_levels" do
      it "should report if valid_levels was not implimented" do
        Base.any_instance.unstub(:valid_levels)

        expect {
          logger = Base.new
        }.to raise_error("The logging class did not supply a valid_levels method")
      end
    end

    describe "#log" do
      it "should report if log was not implimented" do
        logger = Base.new

        expect {
          logger.send(:log, nil, nil, nil)
        }.to raise_error("The logging class did not supply a log method")
      end
    end

    describe "#start" do
      it "should report if log was not implimented" do
        logger = Base.new

        expect {
          logger.send(:start)
        }.to raise_error("The logging class did not supply a start method")
      end
    end

    describe "#map_level" do
      it "should map levels correctly" do
        logger = Base.new

        logger.send(:map_level, :info).should == :info_test
        logger.send(:map_level, :warn).should == :warning_test
        logger.send(:map_level, :debug).should == :debug_test
        logger.send(:map_level, :fatal).should == :crit_test
        logger.send(:map_level, :error).should == :err_test
      end
    end

    describe "#get_next_level" do
      it "should supply the correct next level" do
        logger = Base.new
        logger.set_level(:fatal)

        logger.send(:get_next_level).should == :debug
      end
    end

    describe "#cycle_level" do
      it "should set the level to the next one and log the event" do
        logger = Base.new

        logger.stubs(:get_next_level).returns(:error)

        logger.expects(:set_level).with(:error)
        logger.expects(:log).with(:error, "", "Logging level is now ERROR")

        logger.cycle_level
      end
    end

    describe "#set_level" do
      it "should set the active level" do
        logger = Base.new

        logger.set_level(:error)

        logger.active_level.should == :error
      end

      it "should set the level on the logger" do
        logger = Base.new

        logger.set_level(:error)
      end
    end
  end
end
