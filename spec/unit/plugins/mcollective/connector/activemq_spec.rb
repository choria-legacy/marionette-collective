#!/usr/bin/env rspec

require 'spec_helper'

MCollective::PluginManager.clear

require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/connector/activemq.rb'

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
    describe Activemq do
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

        @c = Activemq.new
        @c.instance_variable_set("@subscriptions", @subscription)
        @c.instance_variable_set("@connection", @connection)
      end

      describe "#initialize" do
        it "should set the @config variable" do
          c = Activemq.new
          c.instance_variable_get("@config").should == @config
        end

        it "should set @subscriptions to an empty list" do
          c = Activemq.new
          c.instance_variable_get("@subscriptions").should == []
        end
      end

      describe "#connect" do
        it "should not try to reconnect if already connected" do
          Log.expects(:debug).with("Already connection, not re-initializing connection").once
          @c.connect
        end

        it "should support new style config" do
          pluginconf = {"activemq.pool.size" => "2",
                        "activemq.pool.1.host" => "host1",
                        "activemq.pool.1.port" => "6163",
                        "activemq.pool.1.user" => "user1",
                        "activemq.pool.1.password" => "password1",
                        "activemq.pool.1.ssl" => "false",
                        "activemq.pool.2.host" => "host2",
                        "activemq.pool.2.port" => "6164",
                        "activemq.pool.2.user" => "user2",
                        "activemq.pool.2.password" => "password2",
                        "activemq.pool.2.ssl" => "true",
                        "activemq.pool.2.ssl.fallback" => "true",
                        "activemq.initial_reconnect_delay" => "0.02",
                        "activemq.max_reconnect_delay" => "40",
                        "activemq.use_exponential_back_off" => "false",
                        "activemq.back_off_multiplier" => "3",
                        "activemq.max_reconnect_attempts" => "5",
                        "activemq.randomize" => "true",
                        "activemq.backup" => "true",
                        "activemq.timeout" => "1",
                        "activemq.max_hbrlck_fails" => 3,
                        "activemq.max_hbread_fails" => 3,
                        "activemq.connect_timeout" => "5"}


          ENV.delete("STOMP_USER")
          ENV.delete("STOMP_PASSWORD")

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          Activemq::EventLogger.expects(:new).returns("logger")

          connector = mock
          connector.expects(:new).with(:backup => true,
                                       :back_off_multiplier => 3,
                                       :max_reconnect_delay => 40.0,
                                       :timeout => 1,
                                       :connect_timeout => 5,
                                       :use_exponential_back_off => false,
                                       :max_reconnect_attempts => 5,
                                       :initial_reconnect_delay => 0.02,
                                       :max_hbread_fails => 3,
                                       :max_hbrlck_fails => 3,
                                       :randomize => true,
                                       :reliable => true,
                                       :logger => "logger",
                                       :connect_headers => {},
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
          @c.expects(:connection_headers).returns({})

          @c.instance_variable_set("@connection", nil)
          @c.connect(connector)
        end
      end

      describe "#stomp_version_supports_heartbeat?" do
        it "should not be supported with stomp 1.2.9" do
          @c.stubs(:stomp_version).returns("1.2.9")
          @c.stomp_version_supports_heartbeat? == false
        end

        it "should be supported with stomp 1.2.10" do
          @c.stubs(:stomp_version).returns("1.2.10")
          @c.stomp_version_supports_heartbeat? == true
        end
      end

      describe "#connection_headers" do
        before do
          @c.stubs(:stomp_version).returns("1.2.10")
        end

        it "should default to stomp 1.0 only" do
          @config.expects(:pluginconf).returns({}).at_least_once
          @c.connection_headers[:"accept-version"] == "1.0"
        end

        it "should support setting the vhost" do
          @config.expects(:pluginconf).returns("activemq.vhost" => "rspec").at_least_once
          @c.connection_headers.should == {:host => "rspec", :"accept-version" => "1.0"}
        end

        it "should log an informational message about not using Stomp 1.1" do
          @config.expects(:pluginconf).returns("activemq.heartbeat_interval" => "0").at_least_once
          Log.expects(:info).with(regexp_matches(/without STOMP 1.1 heartbeats/))
          @c.connection_headers
        end

        it "should not log an informational message about not using Stomp 1.1 if the gem won't support it" do
          @config.expects(:pluginconf).returns("activemq.heartbeat_interval" => "0").at_least_once
          @c.stubs(:stomp_version).returns("1.0.0")
          Log.expects(:info).with(regexp_matches(/without STOMP 1.1 heartbeats/)).never
          @c.connection_headers
        end

        it "should not support stomp 1.1 with older versions of the stomp gem" do
          @config.expects(:pluginconf).returns("activemq.heartbeat_interval" => "30").at_least_once
          @c.expects(:stomp_version).returns("1.0.0").once
          expect { @c.connection_headers }.to raise_error("Setting STOMP 1.1 properties like heartbeat intervals require at least version 1.2.10 of the STOMP gem")
        end

        it "should force the heartbeat to min 30 seconds" do
          @config.expects(:pluginconf).returns("activemq.heartbeat_interval" => "10").at_least_once
          @c.connection_headers[:"heart-beat"].should == "30500,29500"
        end

        it "should default to 1.0 and 1.1 support" do
          @config.expects(:pluginconf).returns("activemq.heartbeat_interval" => "30").at_least_once
          @c.connection_headers[:"accept-version"].should == "1.1,1.0"
        end

        it "should support stomp 1.1 only operation" do
          @config.expects(:pluginconf).returns("activemq.heartbeat_interval" => "30", "activemq.stomp_1_0_fallback" => 0).at_least_once
          @c.connection_headers[:"accept-version"].should == "1.1"
        end
      end

      describe "#ssl_paramaters" do
        it "should ensure all settings are provided" do
          pluginconf = {"activemq.pool.1.host" => "host1",
                        "activemq.pool.1.port" => "6164",
                        "activemq.pool.1.user" => "user1",
                        "activemq.pool.1.password" => "password1",
                        "activemq.pool.1.ssl" => "true",
                        "activemq.pool.1.ssl.cert" => "rspec"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          expect { @c.ssl_parameters(1, false) }.to raise_error("cert, key and ca has to be supplied for verified SSL mode")
        end

        it "should verify the ssl files exist" do
          pluginconf = {"activemq.pool.1.host" => "host1",
                        "activemq.pool.1.port" => "6164",
                        "activemq.pool.1.user" => "user1",
                        "activemq.pool.1.password" => "password1",
                        "activemq.pool.1.ssl" => "true",
                        "activemq.pool.1.ssl.cert" => "rspec.cert",
                        "activemq.pool.1.ssl.key" => "rspec.key",
                        "activemq.pool.1.ssl.ca" => "rspec1.ca,rspec2.ca"}

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
          pluginconf = {"activemq.pool.1.host" => "host1",
                        "activemq.pool.1.port" => "6164",
                        "activemq.pool.1.user" => "user1",
                        "activemq.pool.1.password" => "password1",
                        "activemq.pool.1.ssl" => "true"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          @c.ssl_parameters(1, true).should == true
        end

        it "should fail if fallback isnt enabled" do
          pluginconf = {"activemq.pool.1.host" => "host1",
                        "activemq.pool.1.port" => "6164",
                        "activemq.pool.1.user" => "user1",
                        "activemq.pool.1.password" => "password1",
                        "activemq.pool.1.ssl" => "true"}

          @config.expects(:pluginconf).returns(pluginconf).at_least_once

          expect { @c.ssl_parameters(1, false) }.to raise_error
        end
      end

      describe "#get_key_file" do
        it "should return the filename from the environment variable" do
          ENV["MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_KEY"] = "/path/to/rspec/env"
          @c.get_key_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename defined in the config file if the environment varialbe doesn't exist" do
          ENV.delete("MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_KEY")
          @c.expects(:get_option).with("activemq.pool.2.ssl.key", false).returns("/path/to/rspec/conf")
          @c.get_key_file(2).should == "/path/to/rspec/conf"
        end

      end

      describe "#get_cert_file" do
        it "should return the filename from the environment variable" do
          ENV["MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_CERT"] = "/path/to/rspec/env"
          @c.get_cert_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename defined in the config file if the environment varialbe doesn't exist" do
          ENV.delete("MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_CERT")
          @c.expects(:get_option).with("activemq.pool.2.ssl.cert", false).returns("/path/to/rspec/conf")
          @c.get_cert_file(2).should == "/path/to/rspec/conf"
        end
      end

      describe "#receive" do
        it "should receive from the middleware" do
          payload = mock
          payload.stubs(:command).returns("MESSAGE")
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
          payload.stubs(:command).returns("MESSAGE")
          payload.stubs(:body).returns("msg")
          payload.stubs(:headers).returns("headers")

          Message.stubs(:new).returns("rspec")
          @connection.expects(:receive).raises(::Stomp::Error::NoCurrentConnection).returns(payload).twice
          @c.expects(:sleep).with(1)

          @c.receive.should == "rspec"
        end

        it "should raise an error on failure to receive a frame" do
          @connection.expects(:receive).returns(nil)

          expect { @c.receive }.to raise_error(/No message received/)
        end

        it "should log non-MESSAGE frames" do
          payload = mock
          payload.stubs(:command).returns("ERROR")
          payload.stubs(:body).returns("Out of cheese exception")
          payload.stubs(:headers).returns("headers")

          @connection.expects(:receive).returns(payload)

          Message.stubs(:new)

          Log.expects(:warn).with("Received frame of type 'ERROR' expected 'MESSAGE'")
          Log.stubs(:debug)
          Log.expects(:debug).with('Unexpected \'ERROR\' frame.  Headers: "headers" Body: "Out of cheese exception"')

          @c.receive
        end
      end

      describe "#publish" do
        before do
          @connection.stubs(:publish).with("test", "msg", {}).returns(true)
        end

        it "should base64 encode a message if configured to do so" do
          @c.instance_variable_set("@base64", true)
          @c.expects(:headers_for).returns({})
          @c.expects(:target_for).returns({:name => "test", :headers => {}})
          @connection.expects(:publish).with("test", "msg", {})
          @msg.expects(:base64_encode!)

          @c.publish(@msg)
        end

        it "should not base64 encode if not configured to do so" do
          @c.instance_variable_set("@base64", false)
          @c.expects(:headers_for).returns({})
          @c.expects(:target_for).returns({:name => "test", :headers => {}})
          @connection.expects(:publish).with("test", "msg", {})
          @msg.expects(:base64_encode!).never

          @c.publish(@msg)
        end

        it "should publish the correct message to the correct target with msgheaders" do
          @connection.expects(:publish).with("test", "msg", {"test" => "test"}).once
          @c.expects(:headers_for).returns({"test" => "test"})
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
          msg.expects(:discovered_hosts).returns(["one", "two"])

          @c.expects(:headers_for).with(msg, "one")
          @c.expects(:headers_for).with(msg, "two")
          @connection.expects(:publish).with('/queue/mcollective.nodes', 'msg', nil).twice

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

          request = mock
          request.expects(:headers).returns({"reply-to" => "foo"})

          message.expects(:request).returns(request)

          @c.target_for(message).should == {:name => "foo", :headers => {}}
        end

        it "should create new request targets" do
          message = mock
          message.expects(:type).returns(:request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")

          @c.expects(:make_target).with("rspecagent", :request, "mcollective")
          @c.target_for(message)
        end

        it "should support direct requests" do
          message = mock
          message.expects(:type).returns(:direct_request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")

          @c.expects(:make_target).with("rspecagent", :direct_request, "mcollective")
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

      describe "#headers_for" do
        it "should not set priority header if priority is 0" do
          message = mock
          message.expects(:type).returns(:foo)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          @c.instance_variable_set("@msgpriority", 0)
          @c.headers_for(message).should_not includes("priority")
        end

        it "should return a priority if priority is non 0" do
          message = mock
          message.expects(:type).returns(:foo)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          @c.instance_variable_set("@msgpriority", 1)
          @c.headers_for(message)["priority"].should == 1
        end

        it "should set mc_identity for direct requests" do
          message = mock
          message.expects(:type).returns(:direct_request).twice
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns(nil)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          @c.instance_variable_set("@msgpriority", 0)
          @c.expects(:make_target).with("rspecagent", :reply, "mcollective").returns({:name => "test"})

          headers = @c.headers_for(message, "some.node")
          headers["mc_identity"].should == "some.node"
          headers["reply-to"].should == "test"
        end

        it "should set a reply-to header for :request type messages" do
          message = mock
          message.expects(:type).returns(:request).twice
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns(nil)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          @c.instance_variable_set("@msgpriority", 0)
          @c.expects(:make_target).with("rspecagent", :reply, "mcollective").returns({:name => "test"})
          @c.headers_for(message)["reply-to"].should == "test"
        end

        it "should set reply-to correctly if the message defines it" do
          message = mock
          message.expects(:type).returns(:request).twice
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns("rspec").twice
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          @c.headers_for(message)["reply-to"].should == "rspec"
        end

        it "should set the timestamp and ttl based on the message object" do
          message = mock
          message.expects(:type).returns(:foo)
          message.stubs(:ttl).returns(100)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          headers = @c.headers_for(message)
          headers["timestamp"].should == "1368557431000"
          headers["expires"].should == "1368557541000"
        end
      end

      describe "#make_target" do
        it "should create correct targets" do
          @c.make_target("test", :reply, "mcollective").should == {:name => "/queue/mcollective.reply.rspec_#{$$}", :headers => {}, :id => "/queue/mcollective.reply.rspec_#{$$}"}
          @c.make_target("test", :broadcast, "mcollective").should == {:name => "/topic/mcollective.test.agent", :headers => {}, :id => "/topic/mcollective.test.agent"}
          @c.make_target("test", :request, "mcollective").should == {:name => "/topic/mcollective.test.agent", :headers => {}, :id => "/topic/mcollective.test.agent"}
          @c.make_target("test", :direct_request, "mcollective").should == {:headers=>{}, :name=>"/queue/mcollective.nodes", :id => "/queue/mcollective.nodes"}
          @c.make_target("test", :directed, "mcollective").should == {:name => "/queue/mcollective.nodes", :headers=>{"selector"=>"mc_identity = 'rspec'"}, :id => "mcollective_directed_to_identity"}
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
