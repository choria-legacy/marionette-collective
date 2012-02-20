#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Request do
      before(:each) do
        @req = {:msgtime        => Time.now,
          :senderid        => "spec test",
          :requestid       => "12345",
          :callerid        => "rip"}

        @req[:body] = {:action => "test",
          :data   => {:foo => "bar", :process_results => true},
          :agent  => "tester"}

        @request = Request.new(@req)
      end

      describe "#initialize" do
        it "should set time" do
          @request.time.should == @req[:msgtime]
        end

        it "should set action" do
          @request.action.should == "test"
        end

        it "should set data" do
          @request.data.should == {:foo => "bar", :process_results => true}
        end

        it "should set sender" do
          @request.sender.should == "spec test"
        end

        it "should set agent" do
          @request.agent.should == "tester"
        end

        it "should set uniqid" do
          @request.uniqid.should == "12345"
        end

        it "should set caller" do
          @request.caller.should == "rip"
        end

        it "should set unknown caller if none is supplied" do
          @req.delete(:callerid)
          Request.new(@req).caller.should == "unknown"
        end
      end

      describe "#include?" do
        it "should correctly report on hash contents" do
          @request.include?(:foo).should == true
        end

        it "should return false for non hash data" do
          @req[:body][:data] = "foo"
          Request.new(@req).include?(:foo).should == false
        end
      end

      describe "#should_respond?" do
        it "should return true if the header is absent" do
          @req[:body][:data].delete(:process_results)
          Request.new(@req).should_respond?.should == true
        end

        it "should return correct value" do
          @req[:body][:data][:process_results] = false
          Request.new(@req).should_respond?.should == false
        end
      end

      describe "#[]" do
        it "should return nil for non hash data" do
          @req[:body][:data] = "foo"
          Request.new(@req)["foo"].should == nil
        end

        it "should return correct data" do
          @request[:foo].should == "bar"
        end

        it "should return nil for absent data" do
          @request[:bar].should == nil
        end
      end

      describe "#to_hash" do
        it "should have the correct keys" do
          @request.to_hash.keys.sort.should == [:action, :agent, :data]
        end

        it "should return the correct agent" do
          @request.to_hash[:agent].should == "tester"
        end

        it "should return the correct action" do
          @request.to_hash[:action].should == "test"
        end

        it "should return the correct data" do
          @request.to_hash[:data].should == {:foo => "bar",
            :process_results => true}
        end
      end
    end
  end
end

