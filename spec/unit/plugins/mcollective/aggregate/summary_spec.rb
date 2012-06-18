#!/usr/bin/env rspec

require 'spec_helper'
require File.dirname(__FILE__) + "/../../../../../plugins/mcollective/aggregate/summary.rb"

module MCollective
  class Aggregate
    describe Summary do
      describe "#startup_hook" do
        it "should set the correct result hash" do
          result = Summary.new(:test, [], "%d", :test_action)
          result.result.should == {:value => {}, :type => :collection, :output => :test}
          result.aggregate_format.should == "%d"
        end

        it "should set a defauly aggregate_format if one isn't defined" do
          result = Summary.new(:test, [], nil, :test_action)
          result.aggregate_format.should == "%s : %s"
        end
      end

      describe "#process_result" do
        it "should add the value to the result hash" do
          sum = Summary.new([:test], [], "%d", :test_action)
          sum.process_result(:foo, {:test => :foo})
          sum.result[:value].should == {:foo => 1}
        end

        it "should add the reply values to the result hash if value is an array" do
          sum = Summary.new([:test], [], "%d", :test_action)
          sum.process_result([:foo, :foo, :bar], {:test => [:foo, :foo, :bar]})
          sum.result[:value].should == {:foo => 2, :bar => 1}
        end
      end

      describe "#summarize" do
        it "should return the correct result hash" do
          result_obj = mock
          result_obj.stubs(:new).returns(:success)

          sum = Summary.new([:test], [], "%d", :test_action)
          sum.stubs(:result_class).returns(result_obj)
          sum.summarize.should == :success
        end
      end
    end
  end
end
