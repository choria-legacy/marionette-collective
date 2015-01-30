#!/usr/bin/env rspec

require 'spec_helper'

require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/discovery/mc.rb'

module MCollective
  class Discovery
    describe Mc do
      describe "#discover" do
        before do
          @reply = mock
          @reply.stubs(:payload).returns({:senderid => "rspec"})

          @client = mock
          @client.stubs(:sendreq)
          @client.stubs(:unsubscribe)
          @client.stubs(:receive).returns(@reply)

          Log.stubs(:debug)
        end

        it "should send the ping request via the supplied client" do
          @client.expects(:sendreq).with("ping", "discovery", Util.empty_filter).returns("123456")
          Mc.discover(Util.empty_filter, 1, 1, @client)
        end

        it "should stop early if a limit is supplied" do
          @client.stubs(:receive).returns(@reply).times(10)
          Mc.discover(Util.empty_filter, 1, 10, @client).should == ("rspec," * 10).split(",")
        end

        it "should unsubscribe from the discovery reply source" do
          @client.expects(:unsubscribe).with("discovery", :reply)
          Mc.discover(Util.empty_filter, 1, 10, @client).should == ("rspec," * 10).split(",")
        end
      end
    end
  end
end
