#!/usr/bin/env rspec

require 'spec_helper'

MCollective::PluginManager.clear

require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/connector/stomp.rb'

module MCollective
  module Connector
    describe Stomp do
      before do
        @config = mock
        @config.stubs(:configured).returns(true)
        @config.stubs(:identity).returns("rspec")
        @config.stubs(:collectives).returns(["mcollective"])
        @config.stubs(:topicprefix).returns("/topic/")
        @config.stubs(:topicsep).returns(".")

        logger = mock
        logger.stubs(:log)
        logger.stubs(:start)
        Log.configure(logger)

        Config.stubs(:instance).returns(@config)

        @msg = mock
        @msg.stubs(:base64_encode!)
        @msg.stubs(:payload).returns("msg")
        @msg.stubs(:agent).returns("agent")
        @msg.stubs(:type).returns(:reply)
        @msg.stubs(:collective).returns("mcollective")

        @subscription = mock
        @subscription.stubs("<<").returns(true)
        @subscription.stubs("include?").returns(false)
        @subscription.stubs("delete").returns(false)

        @connection = mock
        @connection.stubs(:subscribe).returns(true)
        @connection.stubs(:unsubscribe).returns(true)

        @c = Stomp.new
        @c.instance_variable_set("@subscriptions", @subscription)
        @c.instance_variable_set("@connection", @connection)
      end

      describe "#initialize" do
        it "should set the @config variable" do
          c = Stomp.new
          c.instance_variable_get("@config").should == @config
        end

        it "should set @subscriptions to an empty list" do
          c = Stomp.new
          c.instance_variable_get("@subscriptions").should == []
        end
      end

      describe "#connect" do
        it "should not try to reconnect if already connected" do
          Log.expects(:debug).with("Already connection, not re-initializing connection").once
          @c.connect
        end

        it "should support old style config" do
          @config.expects(:pluginconf).returns({}).at_least_once
          @c.expects(:get_bool_option).with("stomp.base64", false)
          @c.expects(:get_option).with("stomp.priority", 0)
          @c.expects(:get_env_or_option).with("STOMP_SERVER", "stomp.host").returns("host")
          @c.expects(:get_env_or_option).with("STOMP_PORT", "stomp.port", 6163).returns(6163)
          @c.expects(:get_env_or_option).with("STOMP_USER", "stomp.user").returns("test_user")
          @c.expects(:get_env_or_option).with("STOMP_PASSWORD", "stomp.password").returns("test_password")

          connector = mock
          connector.expects(:new).with("test_user", "test_password", "host", 6163, true)

          @c.instance_variable_set("@connection", nil)
          @c.connect(connector)
        end

        it "should support new style config" do
          pluginconf = {"stomp.pool.size" => "2",
                        "stomp.pool.host1" => "host1",
                        "stomp.pool.port1" => "6163",
                        "stomp.pool.user1" => "user1",
                        "stomp.pool.password1" => "password1",
                        "stomp.pool.ssl1" => "false",
                        "stomp.pool.host2" => "host2",
                        "stomp.pool.port2" => "6164",
                        "stomp.pool.user2" => "user2",
                        "stomp.pool.password2" => "password2",
                        "stomp.pool.ssl2" => "true",
                        "stomp.pool.initial_reconnect_delay" => "0.02",
                        "stomp.pool.max_reconnect_delay" => "40",
                        "stomp.pool.use_exponential_back_off" => "false",
                        "stomp.pool.back_off_multiplier" => "3",
                        "stomp.pool.max_reconnect_attempts" => "5",
                        "stomp.pool.randomize" => "true",
                        "stomp.pool.backup" => "true",
                        "stomp.pool.timeout" => "1"}


          ENV.delete("STOMP_USER")
          ENV.delete("STOMP_PASSWORD")

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          Stomp::EventLogger.expects(:new).returns("logger")

          connector = mock
          connector.expects(:new).with(:backup => true,
                                       :back_off_multiplier => 2,
                                       :max_reconnect_delay => 40.0,
                                       :timeout => 1,
                                       :use_exponential_back_off => false,
                                       :max_reconnect_attempts => 5,
                                       :initial_reconnect_delay => 0.02,
                                       :randomize => true,
                                       :logger => "logger",
                                       :hosts => [{:passcode => 'password1',
                                                   :host => 'host1',
                                                   :port => 6163,
                                                   :ssl => false,
                                                   :login => 'user1'},
                                                  {:passcode => 'password2',
                                                   :host => 'host2',
                                                   :port => 6164,
                                                   :ssl => true,
                                                   :login => 'user2'}
                                                 ])

          @c.instance_variable_set("@connection", nil)
          @c.connect(connector)
        end
      end

      describe "#receive" do
        it "should receive from the middleware" do
          payload = mock
          payload.stubs(:body).returns("msg")
          payload.stubs(:headers).returns("headers")

          @connection.expects(:receive).returns(payload)

          Message.expects(:new).with("msg", payload, :base64 => true, :headers => "headers").returns("message")
          @c.instance_variable_set("@base64", true)

          received = @c.receive
          received.should == "message"
        end
      end

      describe "#publish" do
        before do
          @connection.stubs("respond_to?").with("publish").returns(true)
          @connection.stubs(:publish).with("test", "msg", {}).returns(true)
        end

        it "should base64 encode a message if configured to do so" do
          @c.instance_variable_set("@base64", true)
          @c.expects(:msgheaders).returns({})
          @c.expects(:make_target).returns("test")
          @connection.expects(:publish).with("test", "msg", {})

          @msg.stubs(:reply_to)

          @c.publish(@msg)
        end

        it "should not base64 encode if not configured to do so" do
          @c.instance_variable_set("@base64", false)
          @c.expects(:msgheaders).returns({})
          @c.expects(:make_target).returns("test")

          @connection.expects(:publish).with("test", "msg", {})

          @msg.stubs(:reply_to)

          @c.publish(@msg)
        end

        it "should publish direct requests for each discovered host" do
          @msg.expects(:type).returns(:direct_request).times(3)
          @msg.expects(:discovered_hosts).returns(["one", "two"])

          @c.expects(:make_target).with("agent", :direct_request, "mcollective", "one").returns("target_one")
          @c.expects(:make_target).with("agent", :direct_request, "mcollective", "two").returns("target_two")

          @c.expects(:publish_msg).with("target_one", "msg")
          @c.expects(:publish_msg).with("target_two", "msg")

          @msg.stubs(:reply_to)

          @c.publish(@msg)
        end

        it "should raise an error if specific reply targets are requested" do
          @c.instance_variable_set("@base64", false)

          @msg.expects(:reply_to).returns(:foo)

          expect { @c.publish(@msg) }.to raise_error("Cannot set specific reply to targets with the STOMP plugin")
        end
      end

      describe "#publish_msg" do
        it "should use the publish method if it exists" do
          @connection.expects("respond_to?").with("publish").returns(true)
          @connection.expects(:publish).with("test", "msg", {}).once
          @c.stubs(:msgheaders).returns({})

          @c.publish_msg("test", "msg")
        end

        it "should use the send method if publish does not exist" do
          @connection.expects("respond_to?").with('publish').returns(false)
          @connection.expects(:send).with("test", "msg", {}).once
          @c.stubs(:msgheaders).returns({})

          @c.publish_msg("test", "msg")
        end

        it "should publish the correct message to the correct target with msgheaders" do
          @connection.expects("respond_to?").with("publish").returns(true)
          @connection.expects(:publish).with("test", "msg", {"test" => "test"}).once
          @c.expects(:msgheaders).returns({"test" => "test"})

          @c.publish_msg("test", "msg")
        end

      end

      describe "#make_target" do
        it "should create correct targets" do
          @config.expects(:queueprefix).returns("/queue/").twice

          @c.make_target("test", :broadcast, "mcollective").should == "/topic/mcollective.test.command"
          @c.make_target("test", :directed, "mcollective").should == "/queue/mcollective.2bc84dc69b73db9383b9c6711d2011b7"
          @c.make_target("test", :direct_request, "mcollective", "rspec").should == "/queue/mcollective.2bc84dc69b73db9383b9c6711d2011b7"
          @c.make_target("test", :reply, "mcollective").should == "/topic/mcollective.test.reply"
          @c.make_target("test", :request, "mcollective").should == "/topic/mcollective.test.command"
        end

        it "should raise an error for unknown collectives" do
          expect {
            @c.make_target("test", :broadcast, "foo")
          }.to raise_error("Unknown collective 'foo' known collectives are 'mcollective'")
        end

        it "should raise an error for unknown types" do
          expect {
            @c.make_target("test", :test, "mcollective")
          }.to raise_error("Unknown target type test")
        end
      end

      describe "#unsubscribe" do
        it "should use make_target correctly" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:target => "test", :headers => {}})
          @c.unsubscribe("test", :broadcast, "mcollective")
        end

        it "should unsubscribe from the target" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns("test")
          @connection.expects(:unsubscribe).with("test").once

          @c.unsubscribe("test", :broadcast, "mcollective")
        end

        it "should delete the source from subscriptions" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:target => "test", :headers => {}})
          @subscription.expects(:delete).with({:target => "test", :headers => {}}).once

          @c.unsubscribe("test", :broadcast, "mcollective")
        end
      end

      describe "#subscribe" do
        it "should use the make_target correctly" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns("test")
          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should check for existing subscriptions" do
          @c.expects("make_target").returns("test").once
          @subscription.expects("include?").with("test").returns(false)
          @connection.expects(:subscribe).never

          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should subscribe to the middleware" do
          @c.expects("make_target").returns("test")
          @connection.expects(:subscribe).with("test").once
          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should add to the list of subscriptions" do
          @c.expects("make_target").returns("test")
          @subscription.expects("<<").with("test")
          @c.subscribe("test", :broadcast, "mcollective")
        end
      end

      describe "#disconnect" do
        it "should disconnect from the stomp connection" do
          @connection.expects(:disconnect)
          @c.disconnect
        end
      end

      describe "#msgheaders" do
        it "should return empty headers if priority is 0" do
          @c.instance_variable_set("@msgpriority", 0)
          @c.msgheaders.should == {}
        end

        it "should return a priority if prioritu is non 0" do
          @c.instance_variable_set("@msgpriority", 1)
          @c.msgheaders.should == {"priority" => 1}
        end
      end

      describe "#get_env_or_option" do
        it "should return the environment variable if set" do
          ENV["test"] = "rspec_env_test"

          @c.get_env_or_option("test", nil, nil).should == "rspec_env_test"

          ENV.delete("test")
        end

        it "should return the config option if set" do
          @config.expects(:pluginconf).returns({"test" => "rspec_test"}).twice
          @c.get_env_or_option("test", "test", "test").should == "rspec_test"
        end

        it "should return default if nothing else matched" do
          @config.expects(:pluginconf).returns({}).once
          @c.get_env_or_option("test", "test", "test").should == "test"
        end

        it "should raise an error if no default is supplied" do
          @config.expects(:pluginconf).returns({}).once

          expect {
            @c.get_env_or_option("test", "test")
          }.to raise_error("No test environment or plugin.test configuration option given")
        end
      end

      describe "#get_option" do
        it "should return the config option if set" do
          @config.expects(:pluginconf).returns({"test" => "rspec_test"}).twice
          @c.get_option("test").should == "rspec_test"
        end

        it "should return default option was not found" do
          @config.expects(:pluginconf).returns({}).once
          @c.get_option("test", "test").should == "test"
        end

        it "should raise an error if no default is supplied" do
          @config.expects(:pluginconf).returns({}).once

          expect {
            @c.get_option("test")
          }.to raise_error("No plugin.test configuration option given")
        end
      end

      describe "#get_bool_option" do
        it "should return the default if option isnt set" do
          @config.expects(:pluginconf).returns({}).once
          @c.get_bool_option("test", "default").should == "default"
        end

        ["1", "yes", "true"].each do |boolean|
          it "should map options to true correctly" do
            @config.expects(:pluginconf).returns({"test" => boolean}).twice
            @c.get_bool_option("test", "default").should == true
          end
        end

        ["0", "no", "false"].each do |boolean|
          it "should map options to false correctly" do
            @config.expects(:pluginconf).returns({"test" => boolean}).twice
            @c.get_bool_option("test", "default").should == false
          end
        end

        it "should return default for non boolean options" do
          @config.expects(:pluginconf).returns({"test" => "foo"}).twice
          @c.get_bool_option("test", "default").should == "default"
        end
      end
    end
  end
end
