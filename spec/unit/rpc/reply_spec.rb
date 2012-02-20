#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Reply do
      before(:each) do
        @reply = Reply.new
      end

      describe "#initialize" do
        it "should set an empty data hash" do
          @reply.data.should == {}
        end

        it "should set statuscode to zero" do
          @reply.statuscode.should == 0
        end

        it "should set statusmsg to OK" do
          @reply.statusmsg.should == "OK"
        end
      end

      describe "#fail" do
        it "should set statusmsg" do
          @reply.fail "foo"
          @reply.statusmsg.should == "foo"
        end

        it "should set statuscode to 1 by default" do
          @reply.fail("foo")
          @reply.statuscode.should == 1
        end

        it "should set statuscode" do
          @reply.fail("foo", 2)
          @reply.statuscode.should == 2
        end
      end

      describe "#fail!" do
        it "should set statusmsg" do
          expect {
            @reply.fail! "foo"
          }.to raise_error(RPCAborted, "foo")

          @reply.statusmsg.should == "foo"
        end

        it "should set statuscode to 1 by default" do
          expect {
            @reply.fail! "foo"
          }.to raise_error(RPCAborted)
        end

        it "should set statuscode" do
          expect {
            @reply.fail! "foo", 2
          }.to raise_error(UnknownRPCAction)

          @reply.statuscode.should == 2
        end

        it "should raise RPCAborted for code 1" do
          expect {
            @reply.fail! "foo", 1
          }.to raise_error(RPCAborted)
        end

        it "should raise UnknownRPCAction for code 2" do
          expect {
            @reply.fail! "foo", 2
          }.to raise_error(UnknownRPCAction)
        end

        it "should raise MissingRPCData for code 3" do
          expect {
            @reply.fail! "foo", 3
          }.to raise_error(MissingRPCData)
        end

        it "should raise InvalidRPCData for code 4" do
          expect {
            @reply.fail! "foo", 4
          }.to raise_error(InvalidRPCData)
        end

        it "should raise UnknownRPCError for all other codes" do
          expect {
            @reply.fail! "foo", 5
          }.to raise_error(UnknownRPCError)

          expect {
            @reply.fail! "foo", "x"
          }.to raise_error(UnknownRPCError)
        end
      end

      describe "#[]=" do
        it "should save the correct data to the data hash" do
          @reply[:foo] = "foo1"
          @reply["foo"] = "foo2"

          @reply.data[:foo].should == "foo1"
          @reply.data["foo"].should == "foo2"
        end
      end

      describe "#[]" do
        it "should return the correct saved data" do
          @reply[:foo] = "foo1"
          @reply["foo"] = "foo2"

          @reply[:foo].should == "foo1"
          @reply["foo"].should == "foo2"
        end
      end

      describe "#to_hash" do
        it "should have the correct keys" do
          @reply.to_hash.keys.sort.should == [:data, :statuscode, :statusmsg]
        end

        it "should have the correct statuscode" do
          @reply.fail "meh", 2
          @reply.to_hash[:statuscode].should == 2
        end

        it "should have the correct statusmsg" do
          @reply.fail "meh", 2
          @reply.to_hash[:statusmsg].should == "meh"
        end

        it "should have the correct data" do
          @reply[:foo] = :bar
          @reply.to_hash[:data][:foo].should == :bar
        end
      end
    end
  end
end
