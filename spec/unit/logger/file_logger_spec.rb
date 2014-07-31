#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  require 'mcollective/logger/file_logger'

  module Logger
    describe File_logger do
      let(:mock_logger) { mock('logger') }

      before :each do
        Config.instance.stubs(:loglevel).returns("error")
        Config.instance.stubs(:logfile).returns("testfile")
        Config.instance.stubs(:keeplogs).returns(false)
        Config.instance.stubs(:max_log_size).returns(42)
        ::Logger.stubs(:new).returns(mock_logger)
        mock_logger.stubs(:formatter=)
        mock_logger.stubs(:level=)
      end

      describe "#start" do
        it "should set the level to be that specfied in the config" do
          logger = File_logger.new

          logger.expects(:set_level).with(:error)
          logger.start
        end
      end

      describe '#set_logging_level' do
        it 'should set the level' do
          logger = File_logger.new
          logger.instance_variable_set(:@logger, mock_logger)
          mock_logger.expects(:level=).with(::Logger::ERROR)
          logger.set_level("error")
        end
      end

      describe "#log" do
        it "should delegate to logger" do
          logger = File_logger.new
          logger.instance_variable_set(:@logger, mock_logger)

          mock_logger.expects(:add).with(::Logger::INFO)
          logger.log(:info, "rspec", "message")
        end
      end
    end
  end
end
