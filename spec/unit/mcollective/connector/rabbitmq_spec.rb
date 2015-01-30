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
        Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.use_exponential_back_off", "true").returns(true)
        Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.initial_reconnect_delay", 0.01).returns(0.01)
        Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.back_off_multiplier", 2).returns(2)
        Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.max_reconnect_delay", 30.0).returns(30.0)
        c = Rabbitmq.new
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
        Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.use_reply_exchange", false).returns(false)
      end

      describe "#initialize" do
        before :each do
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.use_exponential_back_off", "true").returns(true)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.initial_reconnect_delay", 0.01).returns(0.01)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.back_off_multiplier", 2).returns(2)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.max_reconnect_delay", 30.0).returns(30.0)
        end

        it "should set the @config variable" do
          c = Rabbitmq.new
          c.instance_variable_get("@config").should == config
        end

        it "should set @subscriptions to an empty list" do
          c = Rabbitmq.new
          c.instance_variable_get("@subscriptions").should == []
        end
      end

      describe "#connect" do
        before :each do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(30)
          Rabbitmq.any_instance.stubs(:get_bool_option).with('rabbitmq.stomp_1_0_fallback', true).returns(true)
          Rabbitmq.any_instance.stubs(:get_bool_option).with('rabbitmq.base64', 'false').returns(false)
          Rabbitmq.any_instance.stubs(:get_option).with('rabbitmq.vhost', '/').returns('rspec')
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.max_reconnect_attempts", 0).returns(5)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.randomize", "false").returns(true)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.backup", "false").returns(true)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.timeout", -1).returns(1)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.connect_timeout", 30).returns(5)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.max_hbrlck_fails", 0).returns(0)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.max_hbread_fails", 2).returns(2)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.base64", 'false').returns(false)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.size").returns(2)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.host").returns("host1")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.port", 61613).returns(6163)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.pool.1.ssl", "false").returns(false)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.2.host").returns("host2")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.2.port", 61613).returns(6164)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.pool.2.ssl", "false").returns(true)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.pool.2.ssl.fallback", "false").returns(true)
          Rabbitmq.any_instance.stubs(:get_env_or_option).with("STOMP_USER", "rabbitmq.pool.1.user", '').returns("user1")
          Rabbitmq.any_instance.stubs(:get_env_or_option).with("STOMP_USER", "rabbitmq.pool.2.user", '').returns("user2")
          Rabbitmq.any_instance.stubs(:get_env_or_option).with("STOMP_PASSWORD", "rabbitmq.pool.1.password", '').returns("password1")
          Rabbitmq.any_instance.stubs(:get_env_or_option).with("STOMP_PASSWORD", "rabbitmq.pool.2.password", '').returns("password2")
          Rabbitmq.any_instance.instance_variable_set("@subscriptions", subscription)
          Rabbitmq.any_instance.instance_variable_set("@connection", connection)
        end

        it "should not try to reconnect if already connected" do
          Log.expects(:debug).with("Already connection, not re-initializing connection").once
          connector.connect
        end

        it "should support new style config" do
          ENV.delete("STOMP_USER")
          ENV.delete("STOMP_PASSWORD")

          Rabbitmq::EventLogger.expects(:new).returns("logger")

          connector_obj = mock
          connector_obj.expects(:new).with(:backup => true,
                                       :back_off_multiplier => 2,
                                       :max_reconnect_delay => 30.0,
                                       :timeout => 1,
                                       :connect_timeout => 5,
                                       :use_exponential_back_off => true,
                                       :max_reconnect_attempts => 5,
                                       :initial_reconnect_delay => 0.01,
                                       :max_hbrlck_fails => 0,
                                       :max_hbread_fails => 2,
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
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(1)
          Rabbitmq.any_instance.stubs(:get_bool_option).with('rabbitmq.stomp_1_0_fallback', true).returns(true)
          Rabbitmq.any_instance.stubs(:get_option).with('rabbitmq.vhost', '/').returns('rspec')
        end

        it "should default to stomp 1.0" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(0)
          connector.connection_headers[:"accept-version"] == "1.0"
        end

        it "should support setting the vhost" do
          connector.connection_headers[:host].should == "rspec"
        end

        it "should log an informational message about not using Stomp 1.1" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(0)
          Log.expects(:info).with(regexp_matches(/without STOMP 1.1 heartbeats/))
          connector.connection_headers
        end

        it "should not log an informational message about not using Stomp 1.1 if the gem won't support it" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(0)
          connector.stubs(:stomp_version).returns("1.0.0")
          Log.expects(:info).with(regexp_matches(/without STOMP 1.1 heartbeats/)).never
          connector.connection_headers
        end

        it "should not support stomp 1.1 with older versions of the stomp gem" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(30)
          connector.expects(:stomp_version).returns("1.0.0").once
          expect { connector.connection_headers }.to raise_error("Setting STOMP 1.1 properties like heartbeat intervals require at least version 1.2.10 of the STOMP gem")
        end

        it "should force the heartbeat to min 30 seconds" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(30)
          connector.connection_headers[:"heart-beat"].should == "30500,29500"
        end

        it "should default to 1.0 and 1.1 support" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(30)
          connector.connection_headers[:"accept-version"].should == "1.1,1.0"
        end

        it "should support stomp 1.1 only operation" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.heartbeat_interval", 0).returns(30)
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.stomp_1_0_fallback", true).returns(false)
          connector.connection_headers[:"accept-version"].should == "1.1"
        end
      end

      describe "#ssl_paramaters" do
        before :each do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.host").returns("host1")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.port").returns("6164")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.user").returns("user1")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.password").returns("password1")
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.pool.1.ssl", false).returns(true)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ciphers", false).returns(false)
        end

        it "should ensure all settings are provided" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.cert", false).returns("rspec")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.key", false).returns(nil)
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ca", false).returns(nil)

          expect { connector.ssl_parameters(1, false) }.to raise_error("cert, key and ca has to be supplied for verified SSL mode")
        end

        it "should verify the ssl files exist" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.cert", false).returns("rspec")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.key", false).returns('rspec.key')
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')

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
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.cert", false).returns("rspec")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.key", false).returns('rspec.key')
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')

          connector.ssl_parameters(1, true).should == true
        end

        it "should fail if fallback isnt enabled" do
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.cert", false).returns("rspec")
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.key", false).returns('rspec.key')
          Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')

          expect { connector.ssl_parameters(1, false) }.to raise_error
        end

        context 'ciphers' do
          before :each do
            Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.cert", false).returns("rspec")
            Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.key", false).returns('rspec.key')
            Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ca", false).returns('rspec1.ca,rspec2.ca')
            File.stubs(:exist?).returns(true)
          end

          it 'should not set ciphers by default' do
            parameters = connector.ssl_parameters(1, false)
            parameters.ciphers.should == false
          end

          it 'should support setting of ciphers' do
            Rabbitmq.any_instance.stubs(:get_option).with("rabbitmq.pool.1.ssl.ciphers", false).returns('TLSv127:!NUTS')
            parameters = connector.ssl_parameters(1, false)
            parameters.ciphers.should == 'TLSv127:!NUTS'
          end
        end
      end

      describe "#get_key_file" do
        it "should return the filename from the environment variable" do
          ENV["MCOLLECTIVE_RABBITMQ_POOL2_SSL_KEY"] = "/path/to/rspec/env"
          connector.get_key_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename define in the config file if the environment variable doesn't exist" do
          ENV.delete("MCOLLECTIVE_RABBITMQ_POOL2_SSL_KEY")
          connector.expects(:get_option).with("rabbitmq.pool.2.ssl.key", false).returns("/path/to/rspec/conf")
          connector.get_key_file(2).should == "/path/to/rspec/conf"
        end
      end

      describe "#get_cert_file" do
        it "shold return the filename from the environment variable" do
          ENV["MCOLLECTIVE_RABBITMQ_POOL2_SSL_CERT"] = "/path/to/rspec/env"
          connector.get_cert_file(2).should == "/path/to/rspec/env"
        end

        it "should return the filename defined in the config file if the environment variable doesn't exist" do
          ENV.delete("MCOLLECTIVE_RABBITMQ_POOL2_SSL_CERT")
          connector.expects(:get_option).with("rabbitmq.pool.2.ssl.cert", false).returns("/path/to/rspec/conf")
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

          expect { connector.receive }.to raise_error(MessageNotReceived, /No message received from RabbitMQ./)
        end

        it "should log and raise UnexpectedMessageType on non-MESSAGE frames" do
          payload = mock
          payload.stubs(:command).returns("ERROR")
          payload.stubs(:body).returns("Out of cheese exception")
          payload.stubs(:headers).returns("headers")

          connection.expects(:receive).returns(payload)

          Message.stubs(:new)

          Log.expects(:debug).with('Waiting for a message from RabbitMQ')
          Log.expects(:debug).with('Unexpected \'ERROR\' frame.  Headers: "headers" Body: "Out of cheese exception"')
          expect { connector.receive }.to raise_error(UnexpectedMessageType, /Received frame of type 'ERROR' expected 'MESSAGE'/)
        end
      end

      describe "#publish" do
        before :each do
          connection.stubs(:publish).with("test", "msg", {}).returns(true)
        end

        it "should base64 encode a message if configured to do so" do
          connector.instance_variable_set("@base64", true)
          connector.expects(:target_for).returns({:name => "test", :headers => {}})
          connection.expects(:publish).with("test", "msg", {})
          msg.expects(:base64_encode!)

          connector.publish(msg)
        end

        it "should not base64 encode if not configured to do so" do
          connector.instance_variable_set("@base64", false)
          connector.expects(:target_for).returns({:name => "test", :headers => {}})
          connection.expects(:publish).with("test", "msg", {})
          msg.expects(:base64_encode!).never

          connector.publish(msg)
        end

        it "should publish the correct message to the correct target with msgheaders" do
          connection.expects(:publish).with("test", "msg", {}).once
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
          msg.stubs(:reply_to).returns("/topic/mcollective")
          msg.stubs(:ttl).returns(60)
          msg.expects(:discovered_hosts).returns(["one", "two"])

          connection.expects(:publish).with('/exchange/mcollective_directed/one',
                                            'msg',
                                            { 'reply-to'    => '/topic/mcollective',
                                              'expiration'  => '70000',
                                              'mc_sender'   => 'rspec',
                                            })
          connection.expects(:publish).with('/exchange/mcollective_directed/two',
                                            'msg',
                                            { 'reply-to'    => '/topic/mcollective',
                                              'expiration'  => '70000',
                                              'mc_sender'   => 'rspec',
                                            })

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
          subscription.expects("include?").with("rspec").returns(false)
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

        it "should not normally subscribe to :reply messages" do
          connection.expects(:subscribe).never
          connector.subscribe("test", :reply, "mcollective")
        end

        it "should subscribe to :reply messages when use_reply_exchange is set" do
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.use_reply_exchange", false).returns(true)
          connector.expects(:make_target).with("test", :reply, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          connection.expects(:subscribe).with("test", {}, "rspec").once

          connector.subscribe("test", :reply, "mcollective")
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

        it "should not normally unsubscribe from :reply messages" do
          connection.expects(:unsubscribe).never
          connector.unsubscribe("test", :reply, "mcollective")
        end

        it "should unsubscribe from :reply messages when use_reply_exchange is set" do
          Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.use_reply_exchange", false).returns(true)
          connector.expects(:make_target).with("test", :reply, "mcollective").returns({:name => "test", :headers => {}, :id => "rspec"})
          connection.expects(:unsubscribe).with("test", {}, "rspec").once

          connector.unsubscribe("test", :reply, "mcollective")
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

          connector.target_for(message).should == {
            :name => "foo",
            :headers => {
              "expiration" => "70000",
              'mc_sender'  => 'rspec',
            },
            :id => "",
          }
        end

        it "should create new request targets" do
          message = mock
          message.expects(:type).returns(:request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns("/topic/rspec")
          message.expects(:ttl).returns(60)

          connector.expects(:make_target).with("rspecagent", :request, "mcollective", "/topic/rspec", nil).returns({:name => "", :headers => {}, :id => nil})
          connector.target_for(message)
        end

        it "should support direct requests" do
          message = mock
          message.expects(:type).returns(:direct_request).times(3)
          message.expects(:agent).returns("rspecagent")
          message.expects(:collective).returns("mcollective")
          message.expects(:reply_to).returns("/topic/rspec")
          message.expects(:ttl).returns(60)

          connector.expects(:make_target).with("rspecagent", :direct_request, "mcollective", "/topic/rspec", nil).returns({:name => "", :headers => {}, :id => nil})
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

      describe "#make_target" do
        context 'rabbitmq.use_reply_exchange' do
          context 'default (false)' do
            it "should create correct targets" do
              connector.make_target("test", :reply, "mcollective").should eq({
                :name => "/temp-queue/mcollective_reply_test",
                :headers => {},
                :id => "mcollective_test_replies",
              })
              connector.make_target("test", :broadcast, "mcollective").should eq({
                :name => "/exchange/mcollective_broadcast/test",
                :headers => { "reply-to" => "/temp-queue/mcollective_reply_test" },
                :id => "mcollective_broadcast_test"
              })
              connector.make_target("test", :request, "mcollective").should eq({
                :name => "/exchange/mcollective_broadcast/test",
                :headers => { "reply-to" => "/temp-queue/mcollective_reply_test" },
                :id => "mcollective_broadcast_test",
              })
              connector.make_target("test", :direct_request, "mcollective", nil, "rspec").should eq({
                :headers => { "reply-to" => "/temp-queue/mcollective_reply_test" },
                :name => "/exchange/mcollective_directed/rspec",
                :id => nil
              })
              connector.make_target("test", :directed, "mcollective").should eq({
                :name => "/exchange/mcollective_directed/rspec",
                :headers => {},
                :id => "mcollective_rspec_directed_to_identity",
              })
              connector.make_target("test", :request, "mcollective", "/topic/rspec", "rspec").should eq({
                :headers => { "reply-to" => "/topic/rspec" },
                :name => "/exchange/mcollective_broadcast/test",
                :id => "mcollective_broadcast_test",
              })
            end
          end

          context 'true' do
            before :each do
              Rabbitmq.any_instance.stubs(:get_bool_option).with("rabbitmq.use_reply_exchange", false).returns(true)
            end

            it "should create correct targets" do
              Client.stubs(:request_sequence).returns(42)
              connector.make_target("test", :reply, "mcollective").should eq({
                :name => "/exchange/mcollective_reply/rspec_#{$$}_42",
                :headers => {},
                :id => "mcollective_test_replies",
              })
              connector.make_target("test", :broadcast, "mcollective").should eq({
                :name => "/exchange/mcollective_broadcast/test",
                :headers => { "reply-to" => "/exchange/mcollective_reply/rspec_#{$$}_42" },
                :id => "mcollective_broadcast_test"
              })
              connector.make_target("test", :request, "mcollective").should eq({
                :name => "/exchange/mcollective_broadcast/test",
                :headers => { "reply-to" => "/exchange/mcollective_reply/rspec_#{$$}_42" },
                :id => "mcollective_broadcast_test",
              })
              connector.make_target("test", :direct_request, "mcollective", nil, "rspec").should eq({
                :headers => { "reply-to" => "/exchange/mcollective_reply/rspec_#{$$}_42" },
                :name => "/exchange/mcollective_directed/rspec",
                :id => nil
              })
              connector.make_target("test", :directed, "mcollective").should eq({
                :name => "/exchange/mcollective_directed/rspec",
                :headers => {},
                :id => "mcollective_rspec_directed_to_identity",
              })
              connector.make_target("test", :request, "mcollective", "/topic/rspec", "rspec").should eq({
                :headers => { "reply-to" => "/topic/rspec" },
                :name => "/exchange/mcollective_broadcast/test",
                :id => "mcollective_broadcast_test",
              })
            end
          end
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
          Rabbitmq.any_instance.unstub(:get_option)
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
          Rabbitmq.any_instance.unstub(:get_bool_option)
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
