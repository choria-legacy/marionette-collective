#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe RunnerStats do
    before do
      Agents.stubs(:agentlist).returns("agents")
      Time.stubs(:now).returns(Time.at(0))

      @stats = RunnerStats.new

      logger = mock
      logger.stubs(:log)
      logger.stubs(:start)
      Log.configure(logger)
    end

    describe "#to_hash" do
      it "should return the correct data" do
        @stats.to_hash.keys.sort.should == [:stats, :threads, :pid, :times, :agents].sort

        @stats.to_hash[:stats].should == {:validated => 0, :unvalidated => 0, :passed => 0, :filtered => 0,
          :starttime => 0, :total => 0, :ttlexpired => 0, :replies => 0}

        @stats.to_hash[:agents].should == "agents"
      end
    end

    [[:ttlexpired, :ttlexpired], [:passed, :passed], [:filtered, :filtered],
     [:validated, :validated], [:received, :total], [:sent, :replies]].each do |tst|
      describe "##{tst.first}" do
        it "should increment #{tst.first}" do
          @stats.send(tst.first)
          @stats.to_hash[:stats][tst.last].should == 1
        end
      end
    end
  end
end
