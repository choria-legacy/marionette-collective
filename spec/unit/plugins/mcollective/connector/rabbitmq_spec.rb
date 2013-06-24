#!/usr/bin/env rspec

require 'spec_helper'

MCollective::PluginManager.clear

require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/connector/rabbitmq.rb'

# create the stomp error class here as it does not always exist
# all versions of the stomp gem and we do not want to tie tests
# to the stomp gem
module Stomp
  module Error
    class DuplicateSubscription < RuntimeError; end
  end
end

module MCollective
  module Connector
    describe Rabbitmq do
      before do
        unless ::Stomp::Error.constants.map{|c| c.to_s}.include?("NoCurrentConnection")
          class ::Stomp::Error::NoCurrentConnection < RuntimeError ; end
        end

        @config = mock
        @config.stubs(:configured).returns(true)
        @config.stubs(:identity).returns("rspec")
        @config.stubs(:collectives).returns(["mcollective"])

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

        @c = Rabbitmq.new
        @c.instance_variable_set("@subscriptions", @subscription)
        @c.instance_variable_set("@connection", @connection)
      end

      describe "#initialize" do
        it "should set the @config variable" do
          c = Rabbitmq.new
          c.instance_variable_get("@config").should == @config
        end

        it "should set @subscriptions to an empty list" do
          c = Rabbitmq.new
          c.instance_variable_get("@subscriptions").should == []
        end
      end

      describe "#connect" do
        it "should not try to reconnect if already connected" do
          Log.expects(:debug).with("Already connection, not re-initializing connection").once
          @c.connect
        end

        it "should support new style config" do
          pluginconf = {"rabbitmq.pool.size" => "2",
                        "rabbitmq.pool.1.host" => "host1",
                        "rabbitmq.pool.1.port" => "6163",
                        "rabbitmq.pool.1.user" => "user1",
                        "rabbitmq.pool.1.password" => "password1",
                        "rabbitmq.pool.1.ssl" => "false",
                        "rabbitmq.pool.2.host" => "host2",
                        "rabbitmq.pool.2.port" => "6164",
                        "rabbitmq.pool.2.user" => "user2",
                        "rabbitmq.pool.2.password" => "password2",
                        "rabbitmq.pool.2.ssl" => "true",
                        "rabbitmq.pool.2.ssl.fallback" => "true",
                        "rabbitmq.initial_reconnect_delay" => "0.02",
                        "rabbitmq.max_reconnect_delay" => "40",
                        "rabbitmq.use_exponential_back_off" => "false",
                        "rabbitmq.back_off_multiplier" => "3",
                        "rabbitmq.max_reconnect_attempts" => "5",
                        "rabbitmq.randomize" => "true",
                        "rabbitmq.backup" => "true",
                        "rabbitmq.timeout" => "1",
                        "rabbitmq.vhost" => "mcollective",
                        "rabbitmq.connect_timeout" => "5"}


          ENV.delete("STOMP_USER")
          ENV.delete("STOMP_PASSWORD")

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          Rabbitmq::EventLogger.expects(:new).returns("logger")

          connector = mock
          connector.expects(:new).with(:backup => true,
                                       :back_off_multiplier => 3,
                                       :max_reconnect_delay => 40.0,
                                       :timeout => 1,
                                       :connect_timeout => 5,
                                       :use_exponential_back_off => false,
                                       :max_reconnect_attempts => 5,
                                       :initial_reconnect_delay => 0.02,
                                       :randomize => true,
                                       :reliable => true,
                                       :logger => "logger",
                                       :connect_headers => {'accept-version' => '1.0', 'host' => 'mcollective'},
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

          @c.expects(:ssl_parameters).with(2, true).returns(true)

          @c.instance_variable_set("@connection", nil)
          @c.connect(connector)
        end
      end

      describe "#ssl_paramaters" do
        it "should ensure all settings are provided" do
          pluginconf = {"rabbitmq.pool.1.host" => "host1",
                        "rabbitmq.pool.1.port" => "6164",
                        "rabbitmq.pool.1.user" => "user1",
                        "rabbitmq.pool.1.password" => "password1",
                        "rabbitmq.pool.1.ssl" => "true",
                        "rabbitmq.pool.1.ssl.cert" => "rspec"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          expect { @c.ssl_parameters(1, false) }.to raise_error("cert, key and ca has to be supplied for verified SSL mode")
        end

        it "should verify the ssl files exist" do
          pluginconf = {"rabbitmq.pool.1.host" => "host1",
                        "rabbitmq.pool.1.port" => "6164",
                        "rabbitmq.pool.1.user" => "user1",
                        "rabbitmq.pool.1.password" => "password1",
                        "rabbitmq.pool.1.ssl" => "true",
                        "rabbitmq.pool.1.ssl.cert" => "rspec.cert",
                        "rabbitmq.pool.1.ssl.key" => "rspec.key",
                        "rabbitmq.pool.1.ssl.ca" => "rspec1.ca,rspec2.ca"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once
          @c.expects(:get_key_file).returns("rspec.key").at_least_once
          @c.expects(:get_cert_file).returns("rspec.cert").at_least_once

          File.expects(:exist?).with("rspec.cert").twice.returns(true)
          File.expects(:exist?).with("rspec.key").twice.returns(true)
          File.expects(:exist?).with("rspec1.ca").twice.returns(true)
          File.expects(:exist?).with("rspec2.ca").twice.returns(false)

          expect { @c.ssl_parameters(1, false) }.to raise_error("Cannot find CA file rspec2.ca")

          @c.ssl_parameters(1, true).should == true
        end

        it "should support fallback mode when there are errors" do
          pluginconf = {"rabbitmq.pool.1.host" => "host1",
                        "rabbitmq.pool.1.port" => "6164",
                        "rabbitmq.pool.1.user" => "user1",
                        "rabbitmq.pool.1.password" => "password1",
                        "rabbitmq.pool.1.ssl" => "true"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          @c.ssl_parameters(1, true).should == true
        end

        it "should fail if fallback isnt enabled" do
          pluginconf = {"rabbitmq.pool.1.host" => "host1",
                        "rabbitmq.pool.1.port" => "6164",
                        "rabbitmq.pool.1.user" => "user1",
                        "rabbitmq.pool.1.password" => "password1",
                        "rabbitmq.pool.1.ssl" => "true"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          expect { @c.ssl_parameters(1, false) }.to raise_error
        end
      end

      describe "#get_key_file" do
        it "should return the filename from the environment variable" do
          ENV["MCOLLECTIVE_RABBITMQ_POOL2_SSL_KEY"] = "/path/to/rspec/env"
          @c.get_key_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename define in the config file if the environment variable doesn't exist" do
          ENV.delete("MCOLLECTIVE_RABBITMQ_POOL2_SSL_KEY")
          @c.expects(:get_option).with("rabbitmq.pool.2.ssl.key", false).returns("/path/to/rspec/conf")
          @c.get_key_file(2).should == "/path/to/rspec/conf"
        end
      end

      describe "#get_cert_file" do
        it "shold return the filename from the environment variable" do
          ENV["MCOLLECTIVE_RABBITMQ_POOL2_SSL_CERT"] = "/path/to/rspec/env"
          @c.get_cert_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename defined in the config file if the environment variable doesn't exist" do
          ENV.delete("MCOLLECTIVE_RABBITMQ_POOL2_SSL_CERT")
          @c.expects(:get_option).with("rabbitmq.pool.2.ssl.cert", false).returns("/path/to/rspec/conf")
          @c.get_cert_file(2).should == "/path/to/rspec/conf"
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

        it "should sleep and retry if recieving while disconnected" do
          payload = mock
          payload.stubs(:body).returns("msg")
          payload.stubs(:headers).returns("headers")

          Message.stubs(:new).returns("rspec")
          @connection.expects(:receive).raises(::Stomp::Error::NoCurrentConnection).returns(payload).twice
          @c.expects(:sleep).with(1)

          @c.receive.should == "rspec"
        end
      end

      describe "#publish" do
        before do
          @connection.stubs(:publish).with("test", "msg", {}).returns(true)
        end

        it "should base64 encode a message if configured to do so" do
          @c.instance_variable_set("@base64", true)
          @c.expects(:target_for).returns({:name => "test", :headers => {}})
          @connection.expects(:publish).with("test", "msg", {})
          @msg.expects(:base64_encode!)

          @c.publish(@msg)
        end

        it "should not base64 encode if not configured to do so" do
          @c.instance_variable_set("@base64", false)
          @c.expects(:target_for).returns({:name => "test", :headers => {}})
          @connection.expects(:publish).with("test", "msg", {})
          @msg.expects(:base64_encode!).never

          @c.publish(@msg)
        end

        it "should publish the correct message to the correct target with msgheaders" do
          @connection.expects(:publish).with("test", "msg", {}).once
          @c.expects(:target_for).returns({:name => "test", :headers => {}})

          @c.publish(@msg)
        end

        it "should publish direct messages based on discovered_hosts" do
          msg = mock
          msg.stubs(:base64_encode!)
          msg.stubs(:payload).returns("msg")
          msg.stubs(:agent).returns("agent")
          msg.stubs(:collective).returns("mcollective")
          msg.stubs(:type).returns(:direct_request)
          msg.stubs(:reply_to).returns("/topic/mcollective")
          msg.stubs(:ttl).returns(60)
          msg.expects(:discovered_hosts).returns(["one", "two"])

          @connection.expects(:publish).with('/exchange/mcollective_directed/one', 'msg', {'reply-to' => '/temp-queue/mcollective_reply_agent', 'expiration' => '70000'})
          @connection.expects(:publish).with('/exchange/mcollective_directed/two', 'msg', {'reply-to' => '/temp-queue/mcollective_reply_agent', 'expiration' => '70000'})

          @c.publish(msg)
        end
      end

      describe "#subscribe" do
        it "should handle duplicate subscription errors" do
          @connection.expects(:subscribe).raises(::Stomp::Error::DuplicateSubscription)
          Log.expects(:error).with(regexp_matches(/already had a matching subscription, ignoring/))
          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should use the make_target correctly" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}})
          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should check for existing subscriptions" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          @subscription.expects("include?").with("rspec").returns(false)
          @connection.expects(:subscribe).never

          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should subscribe to the middleware" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          @connection.expects(:subscribe).with("test", {}, "rspec")
          @c.subscribe("test", :broadcast, "mcollective")
        end

        it "should add to the list of subscriptions" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          @subscription.expects("<<").with("rspec")
          @c.subscribe("test", :broadcast, "mcollective")
        end
      end

      describe "#unsubscribe" do
        it "should use make_target correctly" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}})
          @c.unsubscribe("test", :broadcast, "mcollective")
        end

        it "should unsubscribe from the target" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          @connection.expects(:unsubscribe).with("test", {}, "rspec").once

          @c.unsubscribe("test", :broadcast, "mcollective")
        end

        it "should delete the source from subscriptions" do
          @c.expects("make_target").with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          @subscription.expects(:delete).with("rspec").once

          @c.unsubscribe("test", :broadcast, "mcollective")
        end
      end

      describe "#target_for" do
        it "should create reply targets based on reply-to headers in requests" do
          message = mock
          message.expects(:type).returns(:reply)
          message.expects(:ttl).returns(60)

          request = mock
          request.expects(:headers).returns({"reply-to" => "foo"})

          message.expects(:request).returns(request)

          @c.target_for(message).should == {:name => "foo", :headers => {"expiration" => "70000"}, :id => ""}
        end

        it "should create new request targets" do
          message = mock
          message.expects(:type).returns(:request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns("/topic/rspec")
          message.expects(:ttl).returns(60)

          @c.expects(:make_target).with("rspecagent", :request, "mcollective", "/topic/rspec", nil).returns({:name => "", :headers => {}, :id => nil})
          @c.target_for(message)
        end

        it "should support direct requests" do
          message = mock
          message.expects(:type).returns(:direct_request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns("/topic/rspec")
          message.expects(:ttl).returns(60)

          @c.expects(:make_target).with("rspecagent", :direct_request, "mcollective", "/topic/rspec", nil).returns({:name => "", :headers => {}, :id => nil})
          @c.target_for(message)
        end

        it "should fail for unknown message types" do
          message = mock
          message.stubs(:type).returns(:fail)

          expect {
            @c.target_for(message)
          }.to raise_error("Don't now how to create a target for message type fail")
        end
      end

      describe "#disconnect" do
        it "should disconnect from the stomp connection" do
          @connection.expects(:disconnect)
          @c.disconnect
          @c.connection.should == nil
        end
      end

      describe "#make_target" do
        it "should create correct targets" do
          @c.make_target("test", :reply, "mcollective").should == {:name => "/temp-queue/mcollective_reply_test", :headers => {}, :id => "mcollective_test_replies"}
          @c.make_target("test", :broadcast, "mcollective").should == {:name => "/exchange/mcollective_broadcast/test", :headers => {"reply-to"=>"/temp-queue/mcollective_reply_test"}, :id => "mcollective_broadcast_test"}
          @c.make_target("test", :request, "mcollective").should == {:name => "/exchange/mcollective_broadcast/test", :headers => {"reply-to"=>"/temp-queue/mcollective_reply_test"}, :id => "mcollective_broadcast_test"}
          @c.make_target("test", :direct_request, "mcollective", nil, "rspec").should == {:headers=>{"reply-to"=>"/temp-queue/mcollective_reply_test"}, :name=>"/exchange/mcollective_directed/rspec", :id => nil}
          @c.make_target("test", :directed, "mcollective").should == {:name => "/exchange/mcollective_directed/rspec", :headers=>{}, :id => "rspec_directed_to_identity"}
          @c.make_target("test", :request, "mcollective", "/topic/rspec", "rspec").should == {:headers=>{"reply-to"=>"/topic/rspec"}, :name=>"/exchange/mcollective_broadcast/test", :id => "mcollective_broadcast_test"}
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
        it "should use Util::str_to_bool to translate a boolean value found in the config" do
          @config.expects(:pluginconf).returns({"rspec" => "true"})
          Util.expects(:str_to_bool).with("true").returns(true)

          @c.get_bool_option("rspec", "true").should be_true
        end
      end
    end
  end
end
