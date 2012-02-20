#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Stats do
      before(:each) do
        @expected = {:discoverytime=>0,
          :okcount=>0,
          :blocktime=>0,
          :failcount=>0,
          :noresponsefrom=>[],
          :responses=>0,
          :totaltime=>0,
          :discovered=>0,
          :starttime=>1300031826.0,
          :discovered_nodes=>[]}

        @stats = Stats.new
      end

      describe "#initialize" do
        it "should reset stats on creation" do
          Stats.any_instance.stubs(:reset).returns(true).once
          s = Stats.new
        end
      end

      describe "#reset" do
        it "should initialize data correctly" do
          Time.stubs(:now).returns(Time.at(1300031826))
          s = Stats.new

          @expected.keys.each do |k|
            @expected[k].should == s.send(k)
          end
        end
      end

      describe "#to_hash" do
        it "should return correct stats" do
          Time.stubs(:now).returns(Time.at(1300031826))
          s = Stats.new

          @expected.keys.each do |k|
            @expected[k].should == s.to_hash[k]
          end
        end
      end

      describe "#[]" do
        it "should return stat values" do
          Time.stubs(:now).returns(Time.at(1300031826))
          s = Stats.new

          @expected.keys.each do |k|
            @expected[k].should == s[k]
          end
        end

        it "should return nil for unknown values" do
          @stats["foo"].should == nil
        end
      end

      describe "#ok" do
        it "should increment stats" do
          @stats.ok
          @stats[:okcount].should == 1
        end
      end

      describe "#fail" do
        it "should increment stats" do
          @stats.fail
          @stats.failcount.should == 1
        end
      end

      describe "#time_discovery" do
        it "should set start time correctly" do
          Time.stubs(:now).returns(Time.at(1300031826))

          @stats.time_discovery(:start)

          @stats.instance_variable_get("@discovery_start").should == 1300031826.0
        end

        it "should record the difference correctly" do
          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_discovery(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_discovery(:end)

          @stats.discoverytime.should == 1.0
        end

        it "should handle unknown actions and set discovery time to 0" do
          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_discovery(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_discovery(:stop)

          @stats.discoverytime.should == 0
        end

      end

      describe "#client_stats=" do
        it "should store stats correctly" do
          data = {}
          keys = [:noresponsefrom, :responses, :starttime, :blocktime, :totaltime, :discoverytime]
          keys.each {|k| data[k] = k}

          @stats.client_stats = data

          keys.each do |k|
            @stats[k].should == data[k]
          end
        end

        it "should not store discovery time if it was already stored" do
          data = {}
          keys = [:noresponsefrom, :responses, :starttime, :blocktime, :totaltime, :discoverytime]
          keys.each {|k| data[k] = k}

          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_discovery(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_discovery(:end)

          dtime = @stats.discoverytime

          @stats.client_stats = data

          @stats.discoverytime.should == dtime
        end
      end

      describe "#time_block_execution" do
        it "should set start time correctly" do
          Time.stubs(:now).returns(Time.at(1300031826))

          @stats.time_block_execution(:start)

          @stats.instance_variable_get("@block_start").should == 1300031826.0
        end

        it "should record the difference correctly" do
          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_block_execution(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_block_execution(:end)

          @stats.blocktime.should == 1
        end

        it "should handle unknown actions and set discovery time to 0" do
          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_block_execution(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_block_execution(:stop)

          @stats.blocktime.should == 0
        end
      end

      describe "#discovered_agents" do
        it "should set discovered_nodes" do
          nodes = ["one", "two"]
          @stats.discovered_agents(nodes)
          @stats.discovered_nodes.should == nodes
        end

        it "should set discovered count" do
          nodes = ["one", "two"]
          @stats.discovered_agents(nodes)
          @stats.discovered.should == 2
        end
      end

      describe "#finish_request" do
        it "should calculate totaltime correctly" do
          Time.stubs(:now).returns(Time.at(1300031824))
          @stats.time_discovery(:start)

          Time.stubs(:now).returns(Time.at(1300031825))
          @stats.time_discovery(:end)

          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_block_execution(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_block_execution(:end)

          @stats.discovered_agents(["one", "two", "three"])
          @stats.node_responded("one")
          @stats.node_responded("two")

          @stats.finish_request

          @stats.totaltime.should == 2
        end

        it "should calculate no responses correctly" do
          Time.stubs(:now).returns(Time.at(1300031824))
          @stats.time_discovery(:start)

          Time.stubs(:now).returns(Time.at(1300031825))
          @stats.time_discovery(:end)

          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_block_execution(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_block_execution(:end)

          @stats.discovered_agents(["one", "two", "three"])
          @stats.node_responded("one")
          @stats.node_responded("two")

          @stats.finish_request

          @stats.noresponsefrom.should == ["three"]
        end

        it "should recover from failure correctly" do
          Time.stubs(:now).returns(Time.at(1300031824))
          @stats.time_discovery(:start)

          Time.stubs(:now).returns(Time.at(1300031825))
          @stats.time_discovery(:end)

          Time.stubs(:now).returns(Time.at(1300031826))
          @stats.time_block_execution(:start)

          Time.stubs(:now).returns(Time.at(1300031827))
          @stats.time_block_execution(:end)

          # cause the .each to raise an exception
          @stats.instance_variable_set("@responsesfrom", nil)
          @stats.finish_request

          @stats.noresponsefrom.should == []
          @stats.totaltime.should == 0
        end
      end

      describe "#node_responded" do
        it "should append to the list of nodes" do
          @stats.node_responded "foo"
          @stats.responsesfrom.should == ["foo"]
        end

        it "should create a new array if adding fails" do
          # cause the << to fail
          @stats.instance_variable_set("@responsesfrom", nil)

          @stats.node_responded "foo"
          @stats.responsesfrom.should == ["foo"]
        end
      end

      describe "#no_response_report" do
        it "should create an empty report if all nodes responded" do
          @stats.discovered_agents ["foo"]
          @stats.node_responded "foo"
          @stats.finish_request

          @stats.no_response_report.should == ""
        end

        it "should list all nodes that did not respond" do
          @stats.discovered_agents ["foo", "bar"]
          @stats.finish_request

          @stats.no_response_report.should match(Regexp.new(/No response from.+foo.+bar/m))
        end
      end
    end
  end
end
