#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/aggregate/average'

module MCollective
  class Aggregate
    describe Average do
      describe "#startup_hook" do
        it "should set the correct result hash" do
          result = Average.new(:test, [], "%d", :test_action)
          result.result.should == {:value => 0, :type => :numeric, :output => :test}
          result.aggregate_format.should == "%d"
        end

        it "should set a defauly aggregate_format if one isn't defined" do
          result = Average.new(:test, [], nil, :test_action)
          result.aggregate_format.should == "Average of test: %f"
        end
      end

      describe "#process_result" do
        it "should add the reply value to the result hash" do
          average = Average.new([:test], [], "%d", :test_action)
          average.process_result(1, {:test => 1})
          average.result[:value].should == 1
        end
      end

      describe "#summarize" do
        it "should calculate the average and return a result class" do
          result_obj = mock
          result_obj.stubs(:new).returns(:success)

          average = Average.new([:test], [], "%d", :test_action)
          average.process_result(10, {:test => 10})
          average.process_result(20, {:test => 20})
          average.stubs(:result_class).returns(result_obj)
          average.summarize.should == :success
          average.result[:value].should == 15
        end
      end
    end
  end
end
