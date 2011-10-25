#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

module MCollective
  module RPC
    describe Client do
      describe "#discover" do
        before do
          @config = stub
          @client = stub

          @client.stubs("options=")
          @client.stubs(:collective).returns("mcollective")

          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          MCollective::Client.expects(:new).returns(@client)
        end

        it "should reset when :json or :hosts is provided" do
          Config.any_instance.stubs(:direct_addressing).returns(true)
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
          client.expects(:reset).once
          client.discover(:hosts => ["one"])
        end

        it "should only allow discovery data in direct addressing mode" do
          Config.any_instance.stubs(:direct_addressing).returns(false)
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
          client.expects(:reset).once

          expect {
            client.discover(:hosts => ["one"])
          }.to raise_error("Can only supply discovery data if direct_addressing is enabled")
        end

        it "should parse :hosts and force direct requests" do
          Config.any_instance.stubs(:direct_addressing).returns(true)
          Helpers.expects(:extract_hosts_from_array).with(["one"]).returns(["one"]).once

          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
          client.discover(:hosts => ["one"]).should == ["one"]
          client.instance_variable_get("@force_direct_request").should == true
          client.instance_variable_get("@discovered_agents").should == ["one"]
        end

        it "should parse :json and force direct requests" do
          Config.any_instance.stubs(:direct_addressing).returns(true)
          Helpers.expects(:extract_hosts_from_json).with('["one"]').returns(["one"]).once

          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
          client.discover(:json => '["one"]').should == ["one"]
          client.instance_variable_get("@force_direct_request").should == true
          client.instance_variable_get("@discovered_agents").should == ["one"]
        end

        it "should force direct mode for non regex identity filters" do
          Config.any_instance.stubs(:direct_addressing).returns(true)

          client = Client.new("foo", {:options => {:filter => {"identity" => ["foo"], "agent" => []}, :config => "/nonexisting"}})
          client.discover
          client.instance_variable_get("@discovered_agents").should == ["foo"]
          client.instance_variable_get("@force_direct_request").should == true
        end

        it "should not set direct mode if its disabled" do
          Config.any_instance.stubs(:direct_addressing).returns(false)

          client = Client.new("foo", {:options => {:filter => {"identity" => ["foo"], "agent" => []}, :config => "/nonexisting"}})

          client.discover
          client.instance_variable_get("@force_direct_request").should == false
          client.instance_variable_get("@discovered_agents").should == ["foo"]
        end

        it "should not set direct mode for regex identities" do
          Config.any_instance.stubs(:direct_addressing).returns(false)

          @client.expects(:discover).with({'identity' => ['/foo/'], 'agent' => ['foo']}, nil).once.returns(["foo"])
          client = Client.new("foo", {:options => {:filter => {"identity" => ["/foo/"], "agent" => []}, :config => "/nonexisting"}})

          client.discover
          client.instance_variable_get("@force_direct_request").should == false
          client.instance_variable_get("@discovered_agents").should == ["foo"]
        end

        it "should print status to stderr if in verbose mode" do
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => true, :disctimeout => 2}})

          STDERR.expects(:print).with("Determining the amount of hosts matching filter for 2 seconds .... ")
          STDERR.expects(:puts).with(1)
          client.discover
        end

        it "should not print status to stderr if in verbose mode" do
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})

          STDERR.expects(:print).never
          STDERR.expects(:puts).never

          client.discover
        end

        it "should record the start and end times" do
          Stats.any_instance.expects(:time_discovery).with(:start)
          Stats.any_instance.expects(:time_discovery).with(:end)

          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})

          client.discover
        end

        it "should discover using limits in :first rpclimit mode given a number" do
          Config.any_instance.stubs(:rpclimitmethod).returns(:first)
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2, 1).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})
          client.limit_targets = 1

          client.discover
        end

        it "should not discover using limits in :first rpclimit mode given a string" do
          Config.any_instance.stubs(:rpclimitmethod).returns(:first)
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})
          client.limit_targets = "10%"

          client.discover
        end

        it "should not discover using limits when not in :first mode" do
          Config.any_instance.stubs(:rpclimitmethod).returns(:random)
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})
          client.limit_targets = 1

          client.discover
        end

        it "should ensure force_direct mode is false when doing traditional discovery" do
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})

          client.instance_variable_set("@force_direct_request", true)
          client.discover
          client.instance_variable_get("@force_direct_request").should == false
        end

        it "should store discovered nodes in stats" do
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})

          client.discover
          client.stats.discovered_nodes.should == ["foo"]
        end

        it "should save discovered nodes in RPC" do
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2}})

          RPC.expects(:discovered).with(["foo"]).once
          client.discover
        end
      end
    end
  end
end
