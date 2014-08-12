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

      let(:config) do
        conf = mock
        conf.stubs(:configured).returns(true)
        conf.stubs(:identity).returns("rspec")
        conf.stubs(:collectives).returns(["mcollective"])
        conf
      end

      let(:logger) do
        log = mock
        log.stubs(:log)
        log.stubs(:start)
        Log.configure(log)
        log
      end

      let(:msg) do
        m = mock
        m.stubs(:base64_encode!)
        m.stubs(:payload).returns("msg")
        m.stubs(:agent).returns("agent")
        m.stubs(:type).returns(:reply)
        m.stubs(:collective).returns("mcollective")
        m
      end

      let(:subscription) do
        sub = mock
        sub.stubs(:<<).returns(true)
        sub.stubs(:include?).returns(false)
        sub.stubs(:delete).returns(false)
        sub
      end

      let(:connection) do
        con = mock
        con.stubs(:subscribe).returns(true)
        con.stubs(:unsubscribe).returns(true)
        con
      end

      let(:connector) do
        Activemq.any_instance.stubs(:get_bool_option).with("activemq.use_exponential_back_off", "true").returns(true)
        Activemq.any_instance.stubs(:get_option).with("activemq.initial_reconnect_delay", 0.01).returns(0.01)
        Activemq.any_instance.stubs(:get_option).with("activemq.back_off_multiplier", 2).returns(2)
        Activemq.any_instance.stubs(:get_option).with("activemq.max_reconnect_delay", 30.0).returns(30.0)
        c = Activemq.new
        c.instance_variable_set("@subscriptions", subscription)
        c.instance_variable_set("@connection", connection)
        c
      end

      before do
        unless ::Stomp::Error.constants.map{|c| c.to_s}.include?("NoCurrentConnection")
          class ::Stomp::Error::NoCurrentConnection < RuntimeError ; end
        end

        logger
        Config.stubs(:instance).returns(config)
      end

      describe "#initialize" do
        before :each do
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.use_exponential_back_off", "true").returns(true)
          Activemq.any_instance.stubs(:get_option).with("activemq.initial_reconnect_delay", 0.01).returns(0.01)
          Activemq.any_instance.stubs(:get_option).with("activemq.back_off_multiplier", 2).returns(2)
          Activemq.any_instance.stubs(:get_option).with("activemq.max_reconnect_delay", 30.0).returns(30.0)
        end

        it "should set the @config variable" do
          connector_obj = Activemq.new
          connector_obj.instance_variable_get("@config").should == config
        end

        it "should set @subscriptions to an empty list" do
          connector_obj = Activemq.new
          connector_obj.instance_variable_get("@subscriptions").should == []
        end
      end

      describe "#connect" do
        before :each do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(30)
          Activemq.any_instance.stubs(:get_bool_option).with('activemq.stomp_1_0_fallback', true).returns(true)
          Activemq.any_instance.stubs(:get_bool_option).with('activemq.base64', 'false').returns(false)
          Activemq.any_instance.stubs(:get_option).with('activemq.vhost', 'mcollective').returns('rspec')
          Activemq.any_instance.stubs(:get_option).with("activemq.max_reconnect_attempts", 0).returns(5)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.randomize", "false").returns(true)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.backup", "false").returns(true)
          Activemq.any_instance.stubs(:get_option).with("activemq.timeout", -1).returns(1)
          Activemq.any_instance.stubs(:get_option).with("activemq.connect_timeout", 30).returns(5)
          Activemq.any_instance.stubs(:get_option).with("activemq.max_hbrlck_fails", 2).returns(2)
          Activemq.any_instance.stubs(:get_option).with("activemq.max_hbread_fails", 2).returns(2)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.base64", 'false').returns(false)
          Activemq.any_instance.stubs(:get_option).with("activemq.priority", 0).returns(0)
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.size").returns(2)
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.host").returns("host1")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.port", 61613).returns(6163)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.pool.1.ssl", "false").returns(false)
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.2.host").returns("host2")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.2.port", 61613).returns(6164)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.pool.2.ssl", "false").returns(true)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.pool.2.ssl.fallback", "false").returns(true)
          Activemq.any_instance.stubs(:get_env_or_option).with("STOMP_USER", "activemq.pool.1.user", '').returns("user1")
          Activemq.any_instance.stubs(:get_env_or_option).with("STOMP_USER", "activemq.pool.2.user", '').returns("user2")
          Activemq.any_instance.stubs(:get_env_or_option).with("STOMP_PASSWORD", "activemq.pool.1.password", '').returns("password1")
          Activemq.any_instance.stubs(:get_env_or_option).with("STOMP_PASSWORD", "activemq.pool.2.password", '').returns("password2")
          Activemq.any_instance.instance_variable_set("@subscriptions", subscription)
          Activemq.any_instance.instance_variable_set("@connection", connection)
        end

        it "should not try to reconnect if already connected" do
          Log.expects(:debug).with("Already connection, not re-initializing connection").once
          connector.connect
        end

        it "should support new style config" do
          ENV.delete("STOMP_USER")
          ENV.delete("STOMP_PASSWORD")

          Activemq::EventLogger.expects(:new).returns("logger")

          connector_obj = mock
          connector_obj.expects(:new).with(:backup => true,
                                       :back_off_multiplier => 2,
                                       :max_reconnect_delay => 30.0,
                                       :timeout => 1,
                                       :connect_timeout => 5,
                                       :use_exponential_back_off => true,
                                       :max_reconnect_attempts => 5,
                                       :initial_reconnect_delay => 0.01,
                                       :max_hbread_fails => 2,
                                       :max_hbrlck_fails => 2,
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

          connector.expects(:ssl_parameters).with(2, true).returns(true)
          connector.expects(:connection_headers).returns({})

          connector.instance_variable_set("@connection", nil)
          connector.connect(connector_obj)
        end
      end

      describe "#stomp_version_supports_heartbeat?" do
        it "should not be supported with stomp 1.2.9" do
          connector.stubs(:stomp_version).returns("1.2.9")
          connector.stomp_version_supports_heartbeat? == false
        end

        it "should be supported with stomp 1.2.10" do
          connector.stubs(:stomp_version).returns("1.2.10")
          connector.stomp_version_supports_heartbeat? == true
        end
      end

      describe "#connection_headers" do
        before do
          connector.stubs(:stomp_version).returns("1.2.10")
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(1)
          Activemq.any_instance.stubs(:get_bool_option).with('activemq.stomp_1_0_fallback', true).returns(true)
          Activemq.any_instance.stubs(:get_option).with('activemq.vhost', 'mcollective').returns('rspec')
        end

        it "should default to stomp 1.0 only" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(0)
          connector.connection_headers[:"accept-version"] == "1.0"
        end

        it "should support setting the vhost" do
          connector.connection_headers[:host].should == "rspec"
        end

        it "should log an informational message about not using Stomp 1.1" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(0)
          Log.expects(:info).with(regexp_matches(/without STOMP 1.1 heartbeats/))
          connector.connection_headers
        end

        it "should not log an informational message about not using Stomp 1.1 if the gem won't support it" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(0)
          connector.stubs(:stomp_version).returns("1.0.0")
          Log.expects(:info).with(regexp_matches(/without STOMP 1.1 heartbeats/)).never
          connector.connection_headers
        end

        it "should not support stomp 1.1 with older versions of the stomp gem" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(1)
          connector.expects(:stomp_version).returns("1.0.0").once
          expect { connector.connection_headers }.to raise_error("Setting STOMP 1.1 properties like heartbeat intervals require at least version 1.2.10 of the STOMP gem")
        end

        it "should force the heartbeat to min 30 seconds" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(1)
          connector.connection_headers[:"heart-beat"].should == "30500,29500"
        end

        it "should default to 1.0 and 1.1 support" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(1)
          connector.connection_headers[:"accept-version"].should == "1.1,1.0"
        end

        it "should support stomp 1.1 only operation" do
          Activemq.any_instance.stubs(:get_option).with("activemq.heartbeat_interval", 0).returns(1)
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.stomp_1_0_fallback", true).returns(false)
          connector.connection_headers[:"accept-version"].should == "1.1"
        end
      end

      describe "#ssl_paramaters" do

        before :each do
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.host").returns("host1")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.port").returns("6164")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.user").returns("user1")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.password").returns("password1")
          Activemq.any_instance.stubs(:get_bool_option).with("activemq.pool.1.ssl", false).returns(true)
        end

        it "should ensure all settings are provided" do
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.cert", false).returns("rspec")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.key", false).returns(nil)
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.ca", false).returns(nil)

          expect { connector.ssl_parameters(1, false) }.to raise_error("cert, key and ca has to be supplied for verified SSL mode")
        end

        it "should verify the ssl files exist" do
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.cert", false).returns("rspec")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.key", false).returns('rspec.key')
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')

          connector.expects(:get_key_file).returns("rspec.key").at_least_once
          connector.expects(:get_cert_file).returns("rspec.cert").at_least_once

          File.expects(:exist?).with("rspec.cert").twice.returns(true)
          File.expects(:exist?).with("rspec.key").twice.returns(true)
          File.expects(:exist?).with("rspec1.ca").twice.returns(true)
          File.expects(:exist?).with("rspec2.ca").twice.returns(false)

          expect { connector.ssl_parameters(1, false) }.to raise_error("Cannot find CA file rspec2.ca")

          connector.ssl_parameters(1, true).should == true
        end

        it "should support fallback mode when there are errors" do
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.cert", false).returns("rspec")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.key", false).returns('rspec.key')
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')

          connector.ssl_parameters(1, true).should == true
        end

        it "should fail if fallback isnt enabled" do
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.cert", false).returns("rspec")
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.key", false).returns('rspec.key')
          Activemq.any_instance.stubs(:get_option).with("activemq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')

          expect { connector.ssl_parameters(1, false) }.to raise_error
        end
      end

      describe "#get_key_file" do
        it "should return the filename from the environment variable" do
          ENV["MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_KEY"] = "/path/to/rspec/env"
          connector.get_key_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename defined in the config file if the environment varialbe doesn't exist" do
          ENV.delete("MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_KEY")
          connector.expects(:get_option).with("activemq.pool.2.ssl.key", false).returns("/path/to/rspec/conf")
          connector.get_key_file(2).should == "/path/to/rspec/conf"
        end

      end

      describe "#get_cert_file" do
        it "should return the filename from the environment variable" do
          ENV["MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_CERT"] = "/path/to/rspec/env"
          connector.get_cert_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename defined in the config file if the environment varialbe doesn't exist" do
          ENV.delete("MCOLLECTIVE_ACTIVEMQ_POOL2_SSL_CERT")
          connector.expects(:get_option).with("activemq.pool.2.ssl.cert", false).returns("/path/to/rspec/conf")
          connector.get_cert_file(2).should == "/path/to/rspec/conf"
        end
      end

      describe '#exponential_back_off' do
        it "should not do anything when use_exponential_back_off is off" do
          connector.instance_variable_set(:@use_exponential_back_off, false)
          connector.exponential_back_off.should == nil
        end

        it 'should return values of the expected sequence on subsequent calls' do
          connector.instance_variable_set(:@use_exponential_back_off, true)
          connector.instance_variable_set(:@initial_reconnect_delay, 5.0)
          connector.instance_variable_set(:@back_off_multiplier, 2)
          connector.instance_variable_set(:@max_reconnect_delay, 30.0)
          connector.instance_variable_set(:@reconnect_delay, 5.0)

          connector.exponential_back_off.should == 5
          connector.exponential_back_off.should == 10
          connector.exponential_back_off.should == 20
          connector.exponential_back_off.should == 30
          connector.exponential_back_off.should == 30
        end
      end

      describe "#receive" do
        it "should receive from the middleware" do
          payload = mock
          payload.stubs(:command).returns("MESSAGE")
          payload.stubs(:body).returns("msg")
          payload.stubs(:headers).returns("headers")

          connection.expects(:receive).returns(payload)

          Message.expects(:new).with("msg", payload, :base64 => true, :headers => "headers").returns("message")
          connector.instance_variable_set("@base64", true)

          received = connector.receive
          received.should == "message"
        end

        it "should sleep and retry if recieving while disconnected" do
          payload = mock
          payload.stubs(:command).returns("MESSAGE")
          payload.stubs(:body).returns("msg")
          payload.stubs(:headers).returns("headers")

          Message.stubs(:new).returns("rspec")
          connection.expects(:receive).raises(::Stomp::Error::NoCurrentConnection).returns(payload).twice
          connector.expects(:sleep).with(1)

          connector.receive.should == "rspec"
        end

        it "should raise an error on failure to receive a frame" do
          connection.expects(:receive).returns(nil)

          expect { connector.receive }.to raise_error(MessageNotReceived, /No message received from ActiveMQ./)
        end

        it "should log and raise UnexpectedMessageType on non-MESSAGE frames" do
          payload = mock
          payload.stubs(:command).returns("ERROR")
          payload.stubs(:body).returns("Out of cheese exception")
          payload.stubs(:headers).returns("headers")

          connection.expects(:receive).returns(payload)

          Message.stubs(:new)

          Log.stubs(:debug)
          Log.expects(:debug).with('Unexpected \'ERROR\' frame.  Headers: "headers" Body: "Out of cheese exception"')

          expect { connector.receive }.to raise_error(UnexpectedMessageType, /Received frame of type 'ERROR' expected 'MESSAGE'/)
        end
      end

      describe "#publish" do
        before do
          connection.stubs(:publish).with("test", "msg", {}).returns(true)
        end

        it "should base64 encode a message if configured to do so" do
          connector.instance_variable_set("@base64", true)
          connector.expects(:headers_for).returns({})
          connector.expects(:target_for).returns({:name => "test", :headers => {}})
          connection.expects(:publish).with("test", "msg", {})
          msg.expects(:base64_encode!)

          connector.publish(msg)
        end

        it "should not base64 encode if not configured to do so" do
          connector.instance_variable_set("@base64", false)
          connector.expects(:headers_for).returns({})
          connector.expects(:target_for).returns({:name => "test", :headers => {}})
          connection.expects(:publish).with("test", "msg", {})
          msg.expects(:base64_encode!).never

          connector.publish(msg)
        end

        it "should publish the correct message to the correct target with msgheaders" do
          connection.expects(:publish).with("test", "msg", {"test" => "test"}).once
          connector.expects(:headers_for).returns({"test" => "test"})
          connector.expects(:target_for).returns({:name => "test", :headers => {}})

          connector.publish(msg)
        end

        it "should publish direct messages based on discovered_hosts" do
          msg = mock
          msg.stubs(:base64_encode!)
          msg.stubs(:payload).returns("msg")
          msg.stubs(:agent).returns("agent")
          msg.stubs(:collective).returns("mcollective")
          msg.stubs(:type).returns(:direct_request)
          msg.expects(:discovered_hosts).returns(["one", "two"])

          connector.expects(:headers_for).with(msg, "one")
          connector.expects(:headers_for).with(msg, "two")
          connection.expects(:publish).with('/queue/mcollective.nodes', 'msg', nil).twice

          connector.publish(msg)
        end
      end

      describe "#subscribe" do
        it "should handle duplicate subscription errors" do
          connection.expects(:subscribe).raises(::Stomp::Error::DuplicateSubscription)
          Log.expects(:error).with(regexp_matches(/already had a matching subscription, ignoring/))
          connector.subscribe("test", :broadcast, "mcollective")
        end

        it "should use the make_target correctly" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}})
          connector.subscribe("test", :broadcast, "mcollective")
        end

        it "should check for existing subscriptions" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          subscription.expects(:include?).with("rspec").returns(false)
          connection.expects(:subscribe).never

          connector.subscribe("test", :broadcast, "mcollective")
        end

        it "should subscribe to the middleware" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          connection.expects(:subscribe).with("test", {}, "rspec")
          connector.subscribe("test", :broadcast, "mcollective")
        end

        it "should add to the list of subscriptions" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          subscription.expects(:<<).with("rspec")
          connector.subscribe("test", :broadcast, "mcollective")
        end
      end

      describe "#unsubscribe" do
        it "should use make_target correctly" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}})
          connector.unsubscribe("test", :broadcast, "mcollective")
        end

        it "should unsubscribe from the target" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          connection.expects(:unsubscribe).with("test", {}, "rspec").once

          connector.unsubscribe("test", :broadcast, "mcollective")
        end

        it "should delete the source from subscriptions" do
          connector.expects(:make_target).with("test", :broadcast, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          subscription.expects(:delete).with("rspec").once

          connector.unsubscribe("test", :broadcast, "mcollective")
        end
      end

      describe "#target_for" do
        it "should create reply targets based on reply-to headers in requests" do
          message = mock
          message.expects(:type).returns(:reply)

          request = mock
          request.expects(:headers).returns({"reply-to" => "foo"})

          message.expects(:request).returns(request)

          connector.target_for(message).should == {:name => "foo", :headers => {}}
        end

        it "should create new request targets" do
          message = mock
          message.expects(:type).returns(:request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")

          connector.expects(:make_target).with("rspecagent", :request, "mcollective")
          connector.target_for(message)
        end

        it "should support direct requests" do
          message = mock
          message.expects(:type).returns(:direct_request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")

          connector.expects(:make_target).with("rspecagent", :direct_request, "mcollective")
          connector.target_for(message)
        end

        it "should fail for unknown message types" do
          message = mock
          message.stubs(:type).returns(:fail)

          expect {
            connector.target_for(message)
          }.to raise_error("Don't now how to create a target for message type fail")
        end
      end

      describe "#disconnect" do
        it "should disconnect from the stomp connection" do
          connection.expects(:disconnect)
          connector.disconnect
          connector.connection.should == nil
        end
      end

      describe "#headers_for" do
        it "should not set priority header if priority is 0" do
          message = mock
          message.expects(:type).returns(:foo)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          connector.instance_variable_set("@msgpriority", 0)
          connector.headers_for(message).should_not includes("priority")
        end

        it "should return a priority if priority is non 0" do
          message = mock
          message.expects(:type).returns(:foo)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          connector.instance_variable_set("@msgpriority", 1)
          connector.headers_for(message)["priority"].should == 1
        end

        it "should set mc_identity for direct requests" do
          message = mock
          message.expects(:type).returns(:direct_request).twice
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns(nil)
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          connector.instance_variable_set("@msgpriority", 0)
          connector.expects(:make_target).with("rspecagent", :reply, "mcollective").returns({:name => "test"})

          headers = connector.headers_for(message, "some.node")
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

          connector.instance_variable_set("@msgpriority", 0)
          connector.expects(:make_target).with("rspecagent", :reply, "mcollective").returns({:name => "test"})
          connector.headers_for(message)["reply-to"].should == "test"
        end

        it "should set reply-to correctly if the message defines it" do
          message = mock
          message.expects(:type).returns(:request).twice
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns("rspec").twice
          message.stubs(:ttl).returns(30)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          connector.headers_for(message)["reply-to"].should == "rspec"
        end

        it "should set the timestamp and ttl based on the message object" do
          message = mock
          message.expects(:type).returns(:foo)
          message.stubs(:ttl).returns(100)

          Time.expects(:now).twice.returns(Time.at(1368557431))

          headers = connector.headers_for(message)
          headers["timestamp"].should == "1368557431000"
          headers["expires"].should == "1368557541000"
        end
      end

      describe "#make_target" do
        it "should create correct targets" do
          connector.make_target("test", :reply, "mcollective").should == {
            :name => "/queue/mcollective.reply.rspec_#{$$}",
            :headers => {},
            :id => "/queue/mcollective.reply.rspec_#{$$}",
          }

          connector.make_target("test", :broadcast, "mcollective").should == {
            :name => "/topic/mcollective.test.agent",
            :headers => {},
            :id => "/topic/mcollective.test.agent",
          }

          connector.make_target("test", :request, "mcollective").should == {
            :name => "/topic/mcollective.test.agent",
            :headers => {},
            :id => "/topic/mcollective.test.agent",
          }

          connector.make_target("test", :direct_request, "mcollective").should == {
            :name => "/queue/mcollective.nodes",
            :headers => {},
            :id => "/queue/mcollective.nodes",
          }

          connector.make_target("test", :directed, "mcollective").should == {
            :name => "/queue/mcollective.nodes",
            :headers => {
              "selector" => "mc_identity = 'rspec'",
            },
            :id => "mcollective_directed_to_identity",
          }
        end

        it "should raise an error for unknown collectives" do
          expect {
            connector.make_target("test", :broadcast, "foo")
          }.to raise_error("Unknown collective 'foo' known collectives are 'mcollective'")
        end

        it "should raise an error for unknown types" do
          expect {
            connector.make_target("test", :test, "mcollective")
          }.to raise_error("Unknown target type test")
        end
      end


      describe "#get_env_or_option" do
        it "should return the environment variable if set" do
          ENV["test"] = "rspec_env_test"

          connector.get_env_or_option("test", nil, nil).should == "rspec_env_test"

          ENV.delete("test")
        end

        it "should return the config option if set" do
          config.expects(:pluginconf).returns({"test" => "rspec_test"}).twice
          connector.get_env_or_option("test", "test", "test").should == "rspec_test"
        end

        it "should return default if nothing else matched" do
          config.expects(:pluginconf).returns({}).once
          connector.get_env_or_option("test", "test", "test").should == "test"
        end

        it "should raise an error if no default is supplied" do
          config.expects(:pluginconf).returns({}).once

          expect {
            connector.get_env_or_option("test", "test")
          }.to raise_error("No test environment or plugin.test configuration option given")
        end
      end

      describe "#get_option" do
        before :each do
          # realize the connector let so that we can unstub it
          connector
          Activemq.any_instance.unstub(:get_option)
        end

        it "should return the config option if set" do
          config.expects(:pluginconf).returns({"test" => "rspec_test"}).twice
          connector.get_option("test").should == "rspec_test"
        end

        it "should return default option was not found" do
          config.expects(:pluginconf).returns({}).once
          connector.get_option("test", "test").should == "test"
        end

        it "should raise an error if no default is supplied" do
          config.expects(:pluginconf).returns({}).once

          expect {
            connector.get_option("test")
          }.to raise_error("No plugin.test configuration option given")
        end
      end

      describe "#get_bool_option" do
        before :each do
          # realize the connector let so that we can unstub it
          connector
          Activemq.any_instance.unstub(:get_bool_option)
        end

        it "should use Util::str_to_bool to translate a boolean value found in the config" do
          config.expects(:pluginconf).returns({"rspec" => "true"})
          Util.expects(:str_to_bool).with("true").returns(true)

          connector.get_bool_option("rspec", "true").should be_true
        end
      end
    end
  end
end
