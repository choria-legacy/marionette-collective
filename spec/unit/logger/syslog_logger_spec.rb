#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  unless Util.windows?
    require 'mcollective/logger/syslog_logger'

    module Logger
      describe Syslog_logger do
        describe "#start" do
          before do
            Config.any_instance.stubs(:logfacility).returns("user")
            Config.any_instance.stubs(:loglevel).returns("error")
          end

          it "should close the syslog if already opened" do
            Syslog.expects("opened?").returns(true)
            Syslog.expects(:close).once
            Syslog.expects(:open).once

            logger = Syslog_logger.new
            logger.start
          end

          it "should open syslog with the correct facility" do
            logger = Syslog_logger.new
            Syslog.expects(:open).with("rspec", 3, Syslog::LOG_USER).once
            logger.start
          end

          it "should set the logger level correctly" do
            logger = Syslog_logger.new
            Syslog.expects(:open).with("rspec", 3, Syslog::LOG_USER).once
            logger.expects(:set_level).with(:error).once
            logger.start
          end
        end

        describe "#syslog_facility" do
          it "should support valid facilities" do
            logger = Syslog_logger.new
            logger.syslog_facility("LOCAL1").should == Syslog::LOG_LOCAL1
            logger.syslog_facility("local1").should == Syslog::LOG_LOCAL1
          end

          it "should set LOG_USER for unknown facilities" do
            logger = Syslog_logger.new
            IO.any_instance.expects(:puts).with("Invalid syslog facility rspec supplied, reverting to USER")
            logger.syslog_facility("rspec").should == Syslog::LOG_USER
          end
        end

        describe "#log" do
          it "should log higher than configured levels" do
            logger = Syslog_logger.new
            logger.set_level(:debug)
            Syslog.expects(:err).once
            logger.log(:error, "rspec", "rspec")
          end

          it "should not log lower than configured levels" do
            logger = Syslog_logger.new
            logger.set_level(:fatal)
            Syslog.expects(:debug).never
            logger.log(:debug, "rspec", "rspec")
          end

          it "should log using the correctly mapped level" do
            logger = Syslog_logger.new
            Syslog.expects(:err).with("rspec rspec").once
            logger.set_level(:debug)
            logger.log(:error, "rspec", "rspec")
          end

          it "should resort to STDERR output if all else fails" do
            logger = Syslog_logger.new
            IO.any_instance.expects(:puts).with("error: rspec").once

            logger.log(:error, "rspec", "rspec")
          end
        end
      end
    end
  end
end
