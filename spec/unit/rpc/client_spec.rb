#!/usr/bin/env ruby

require 'spec_helper'

module MCollective
  module RPC
    describe Client do
      describe "#limit_method" do
        before do
          client = stub

          client.stubs("options=")
          client.stubs(:collective).returns("mcollective")

          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          MCollective::Client.expects(:new).returns(client)
          Config.any_instance.stubs(:direct_addressing).returns(true)

          @client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
        end

        it "should force strings to symbols" do
          @client.limit_method = "first"
          @client.limit_method.should == :first
        end

        it "should only allow valid methods" do
          @client.limit_method = :first
          @client.limit_method.should == :first
          @client.limit_method = :random
          @client.limit_method.should == :random

          expect { @client.limit_method = :fail }.to raise_error(/Unknown/)
          expect { @client.limit_method = "fail" }.to raise_error(/Unknown/)
        end
      end
      describe "#limit_targets=" do
        before do
          client = stub

          client.stubs("options=")
          client.stubs(:collective).returns("mcollective")

          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          MCollective::Client.expects(:new).returns(client)
          Config.any_instance.stubs(:direct_addressing).returns(true)

          @client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
        end

        it "should support percentages" do
          @client.limit_targets = "10%"
          @client.limit_targets.should == "10%"
        end

        it "should support integers" do
          @client.limit_targets = 10
          @client.limit_targets.should == 10
          @client.limit_targets = "20"
          @client.limit_targets.should == 20
          @client.limit_targets = 1.1
          @client.limit_targets.should == 1
          @client.limit_targets = 1.7
          @client.limit_targets.should == 1
        end

        it "should not invalid limits to be set" do
          expect { @client.limit_targets = "a" }.to raise_error /Invalid/
          expect { @client.limit_targets = "%1" }.to raise_error /Invalid/
          expect { @client.limit_targets = "1.1" }.to raise_error /Invalid/
        end
      end

      describe "#call_agent_batched" do
        before do
          @client = stub

          @client.stubs("options=")
          @client.stubs(:collective).returns("mcollective")

          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          MCollective::Client.expects(:new).returns(@client)
          Config.any_instance.stubs(:direct_addressing).returns(true)
        end

        it "should require direct addressing" do
          Config.any_instance.stubs(:direct_addressing).returns(false)
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})

          expect {
            client.send(:call_agent_batched, "foo", {}, {}, 1, 1)
          }.to raise_error("Batched requests requires direct addressing")
        end

        it "should require that all results be processed" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})

          expect {
            client.send(:call_agent_batched, "foo", {:process_results => false}, {}, 1, 1)
          }.to raise_error("Cannot bypass result processing for batched requests")
        end

        it "should only accept integer batch sizes" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})

          expect {
            client.send(:call_agent_batched, "foo", {}, {}, "foo", 1)
          }.to raise_error(/invalid value for Integer/)
        end

        it "should only accept float sleep times" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})

          expect {
            client.send(:call_agent_batched, "foo", {}, {}, 1, "foo")
          }.to raise_error(/invalid value for Float/)
        end

        it "should batch hosts in the correct size" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :stderr => StringIO.new}})

          client.expects(:new_request).returns("req")

          discovered = mock
          discovered.stubs(:size).returns(1)
          discovered.expects(:in_groups_of).with(10).raises("spec pass")
          @client.stubs(:discover).returns(discovered)

          expect { client.send(:call_agent_batched, "foo", {}, {}, 10, 1) }.to raise_error("spec pass")
        end

        it "should force direct requests" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :stderr => StringIO.new}})

          Message.expects(:new).with('req', nil, {:type => :direct_request, :agent => 'foo', :filter => nil, :options => {}, :collective => 'mcollective'}).raises("spec pass")
          client.expects(:new_request).returns("req")

          @client.stubs(:discover).returns(["test"])

          expect { client.send(:call_agent_batched, "foo", {}, {}, 1, 1) }.to raise_error("spec pass")
        end

        it "should process blocks correctly" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :stderr => StringIO.new}})

          msg = mock
          msg.expects(:discovered_hosts=).times(10)

          stats = {:noresponsefrom => [], :responses => 0, :blocktime => 0, :totaltime => 0, :discoverytime => 0}

          Message.expects(:new).with('req', nil, {:type => :direct_request, :agent => 'foo', :filter => nil, :options => {}, :collective => 'mcollective'}).returns(msg).times(10)
          client.expects(:new_request).returns("req")
          client.expects(:sleep).with(1.0).times(9)

          @client.stubs(:discover).returns([1,2,3,4,5,6,7,8,9,0])
          @client.expects(:req).with(msg).yields("result").times(10)
          @client.stubs(:stats).returns stats

          client.expects(:process_results_with_block).with("foo", "result", instance_of(Proc)).times(10)

          result = client.send(:call_agent_batched, "foo", {}, {}, 1, 1) { }
          result.class.should == Stats
        end

        it "should return an array of results in array mode" do
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :stderr => StringIO.new}})

          msg = mock
          msg.expects(:discovered_hosts=).times(10)

          stats = {:noresponsefrom => [], :responses => 0, :blocktime => 0, :totaltime => 0, :discoverytime => 0}

          Message.expects(:new).with('req', nil, {:type => :direct_request, :agent => 'foo', :filter => nil, :options => {}, :collective => 'mcollective'}).returns(msg).times(10)
          client.expects(:new_request).returns("req")
          client.expects(:sleep).with(1.0).times(9)

          @client.stubs(:discover).returns([1,2,3,4,5,6,7,8,9,0])
          @client.expects(:req).with(msg).yields("result").times(10)
          @client.stubs(:stats).returns stats

          client.expects(:process_results_without_block).with("result", "foo").returns("rspec").times(10)

          client.send(:call_agent_batched, "foo", {}, {}, 1, 1).should == ["rspec", "rspec", "rspec", "rspec", "rspec", "rspec", "rspec", "rspec", "rspec", "rspec"]
        end
      end

      describe "#batch_sleep_time=" do
        before do
          @client = stub

          @client.stubs("options=")
          @client.stubs(:collective).returns("mcollective")

          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          MCollective::Client.expects(:new).returns(@client)
        end

        it "should correctly set the sleep" do
          Config.any_instance.stubs(:direct_addressing).returns(true)

          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
          client.batch_sleep_time = 5
          client.batch_sleep_time.should == 5
        end

        it "should only allow batch sleep to be set for direct addressing capable clients" do
          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})

          expect { client.batch_sleep_time = 5 }.to raise_error("Can only set batch sleep time if direct addressing is supported")
        end
      end

      describe "#batch_size=" do
        before do
          @client = stub

          @client.stubs("options=")
          @client.stubs(:collective).returns("mcollective")

          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          MCollective::Client.expects(:new).returns(@client)
        end

        it "should correctly set the size" do
          Config.any_instance.stubs(:direct_addressing).returns(true)

          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})
          client.batch_size = 5
          client.batch_size.should == 5
        end

        it "should only allow batch size to be set for direct addressing capable clients" do
          Config.any_instance.stubs(:loadconfig).with("/nonexisting").returns(true)
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting"}})

          expect { client.batch_size = 5 }.to raise_error("Can only set batch size if direct addressing is supported")
        end
      end

      describe "#discover" do
        before do
          @client = stub

          @client.stubs("options=")
          @client.stubs(:collective).returns("mcollective")

          @stderr = stub
          @stdout = stub

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
          @stderr.expects(:print).with("Determining the amount of hosts matching filter for 2 seconds .... ")
          @stderr.expects(:puts).with(1)

          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => true, :disctimeout => 2, :stderr => @stderr, :stdout => @stdout}})
          client.discover
        end

        it "should not print status to stderr if in verbose mode" do
          @client.expects(:discover).with({'identity' => [], 'compound' => [], 'fact' => [], 'agent' => ['foo'], 'cf_class' => []}, 2).returns(["foo"])
          client = Client.new("foo", {:options => {:filter => Util.empty_filter, :config => "/nonexisting", :verbose => false, :disctimeout => 2, :stderr => @stderr, :stdout => @stdout}})

          @stderr.expects(:print).never
          @stderr.expects(:puts).never

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
