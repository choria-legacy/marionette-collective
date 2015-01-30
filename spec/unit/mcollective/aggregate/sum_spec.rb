#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/aggregate/sum'

module MCollective
  class Aggregate
    describe Sum do
      describe "#startup_hook" do
        it "should set the correct result hash" do
          result = Sum.new(:test, [], "%d", :test_action)
          result.result.should == {:value => 0, :type => :numeric, :output => :test}
          result.aggregate_format.should == "%d"
        end

        it "should set a defauly aggregate_format if one isn't defined" do
          result = Sum.new(:test, [], nil, :test_action)
          result.aggregate_format.should == "Sum of test: %f"
        end
      end

      describe "#process_result" do
        it "should add the reply value to the result hash" do
          average = Sum.new([:test], [], "%d", :test_action)
          average.process_result(1, {:test => 1})
          average.result[:value].should == 1
        end
      end
    end
  end
end
