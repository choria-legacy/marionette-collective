#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  require 'mcollective/logger/console_logger'

  module Logger
    describe Console_logger do
      describe "#start" do
        it "should default to :info and allow the config to override" do
          logger = Console_logger.new
          logger.expects(:set_level).with(:info)
          Config.instance.expects(:configured).returns(true)
          Config.instance.expects(:loglevel).returns("error")
          logger.expects(:set_level).with(:error)
          logger.start
        end
      end

      describe "#color" do
        it "should not colorize if color was disabled" do
          logger = Console_logger.new
          Config.instance.stubs(:color).returns(false)
          logger.color(:error).should == ""
          logger.color(:reset).should == ""
        end

        it "should correctly colorize by level" do
          logger = Console_logger.new
          Config.instance.stubs(:color).returns(true)
          logger.color(:error).should == Util.color(:red)
          logger.color(:reset).should == Util.color(:reset)
        end
      end

      describe "#log" do
        it "should log higher than configured levels" do
          io = StringIO.new
          io.expects(:puts).with("error 2012/07/03 15:11:35: rspec message")

          time = stub
          time.expects(:strftime).returns("2012/07/03 15:11:35")

          Time.expects(:new).returns(time)

          Config.instance.stubs(:color).returns(false)
          logger = Console_logger.new
          logger.set_level(:warn)
          logger.log(:error, "rspec", "message", io)
        end

        it "should not log lower than configured levels" do
          io = StringIO.new
          io.expects(:puts).never

          logger = Console_logger.new
          logger.set_level(:warn)
          logger.log(:debug, "rspec", "message", io)
        end

        it "should resort to STDERR output if all else fails" do
          io = StringIO.new
          io.expects(:puts).raises

          last_resort_io = StringIO.new
          last_resort_io.expects(:puts).with("warn: message")

          logger = Console_logger.new
          logger.set_level(:debug)
          logger.log(:warn, "rspec", "message", io, last_resort_io)
        end
      end
    end
  end
end
