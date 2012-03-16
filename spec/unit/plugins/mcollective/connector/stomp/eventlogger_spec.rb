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

          [:on_miscerr, :on_connecting, :on_connected, :on_disconnect, :on_connectfail, :on_ssl_connecting, :on_ssl_connected].each do |meth|
            plugin.respond_to?(meth).should == true
          end
        end

        describe "#stomp_url" do
          it "should create valid stomp urls" do
            EventLogger.new.stomp_url({:cur_login => "rspec", :cur_host => "localhost", :cur_port => 123}).should == "stomp://rspec@localhost:123"
            EventLogger.new.stomp_url({:cur_login => "rspec", :cur_host => "localhost", :cur_port => 123, :cur_ssl => false}).should == "stomp://rspec@localhost:123"
            EventLogger.new.stomp_url({:cur_login => "rspec", :cur_host => "localhost", :cur_port => 123, :cur_ssl => true}).should == "stomp+ssl://rspec@localhost:123"
          end
        end
      end
    end
  end
end
