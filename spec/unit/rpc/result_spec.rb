#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Result do
      before(:each) do
        @result = Result.new("tester", "test", {:foo => "bar", :bar => "baz"})
      end

      it "should include Enumerable" do
        Result.ancestors.include?(Enumerable).should == true
      end

      describe "#initialize" do
        it "should set the agent" do
          @result.agent.should == "tester"
        end

        it "should set the action" do
          @result.action.should == "test"
        end

        it "should set the results" do
          @result.results.should == {:foo => "bar", :bar => "baz"}
        end
      end

      describe "#[]" do
        it "should access the results hash and return correct data" do
          @result[:foo].should == "bar"
          @result[:bar].should == "baz"
        end
      end

      describe "#[]=" do
        it "should set the correct result data" do
          @result[:meh] = "blah"

          @result[:foo].should == "bar"
          @result[:bar].should == "baz"
          @result[:meh].should == "blah"
        end
      end

      describe "#each" do
        it "should itterate all the pairs" do
          data = {}

          @result.each {|k,v| data[k] = v}

          data[:foo].should == "bar"
          data[:bar].should == "baz"
        end
      end

      describe "#to_json" do
        it "should correctly json encode teh data" do
          result = Result.new("tester", "test", {:statuscode => 0, :statusmsg => "OK", :sender => "rspec",  :data => {:foo => "bar", :bar => "baz"}})
          JSON.load(result.to_json).should == {"agent" => "tester", "action" => "test", "statuscode" => 0, "statusmsg" => "OK", "sender" => "rspec", "data" => {"foo" => "bar", "bar" => "baz"}}
        end
      end
    end
  end
end
