#!/usr/bin/env rspec

require 'spec_helper'

MCollective::PluginManager.clear

require File.dirname(__FILE__) + '/../../../../../../plugins/mcollective/connector/stomp.rb'

module MCollective
  module Connector
    class Stomp
      describe EventLogger do
        before do
        end

        it "should have valid call back methods" do
          plugin = EventLogger.new

          [:on_miscerr, :on_connecting, :on_connected, :on_disconnect, :on_connectfail].each do |meth|
            plugin.respond_to?(meth).should == true
          end
        end

        describe "#stomp_url" do
          it "should create valid stomp urls" do
            EventLogger.new.stomp_url({:cur_login => "rspec", :cur_host => "localhost", :cur_port => 123}).should == "stomp://rspec@localhost:123"
          end
        end
      end
    end
  end
end
