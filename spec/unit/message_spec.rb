#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Message do
    before do
      Config.instance.set_config_defaults("")
    end

    describe "#initialize" do
      it "should set defaults" do
        m = Message.new("payload", "message")
        m.payload.should == "payload"
        m.message.should == "message"
        m.request.should == nil
        m.headers.should == {}
        m.agent.should == nil
        m.collective.should == nil
        m.type.should == :message
        m.filter.should == Util.empty_filter
        m.requestid.should == nil
        m.base64?.should == false
        m.options.should == {}
        m.discovered_hosts.should == nil
        m.ttl.should == 60
        m.validated.should == false
        m.msgtime.should == 0
        m.expected_msgid == nil
      end

      it "should set all supplied options" do
        Message.any_instance.expects(:base64_decode!)

        m = Message.new("payload", "message", :base64 => true,
                        :agent => "rspecagent",
                        :headers => {:rspec => "test"},
                        :type => :rspec,
                        :filter => "filter",
                        :options => {:ttl => 30},
                        :collective => "collective")
        m.payload.should == "payload"
        m.message.should == "message"
        m.request.should == nil
        m.headers.should == {:rspec => "test"}
        m.agent.should == "rspecagent"
        m.collective.should == "collective"
        m.type.should == :rspec
        m.filter.should == "filter"
        m.base64?.should == true
        m.options.should == {:ttl => 30}
        m.ttl.should == 30
      end

      it "if given a request it should set options based on the request" do
        request = mock
        request.expects(:agent).returns("request")
        request.expects(:collective).returns("collective")

        m = Message.new("payload", "message", :request => request)
        m.agent.should == "request"
        m.collective.should == "collective"
        m.type.should == :reply
        m.request.should == request
      end
    end

    describe "#reply_to=" do
      it "should only set the reply-to header for requests" do
        Config.instance.instance_variable_set("@direct_addressing", true)
        m = Message.new("payload", "message", :type => :reply)
        m.discovered_hosts = ["foo"]
        expect { m.reply_to = "foo" }.to raise_error(/reply targets/)

        [:request, :direct_request].each do |t|
          m.type = t
          m.reply_to = "foo"
          m.reply_to.should == "foo"
        end
      end
    end

    describe "#expected_msgid=" do
      it "should correctly set the property" do
        m = Message.new("payload", "message", :type => :reply)
        m.expected_msgid = "rspec test"
        m.expected_msgid.should == "rspec test"
      end

      it "should only be set for reply messages" do
        m = Message.new("payload", "message", :type => :request)

        expect {
          m.expected_msgid = "rspec test"
        }.to raise_error("Can only store the expected msgid for reply messages")
      end
    end

    describe "#base64_decode!" do
      it "should not decode if not encoded" do
        SSL.expects(:base64_decode).never
        m = Message.new("payload", "message")
      end

      it "should decode encoded messages" do
        SSL.expects(:base64_decode)
        m = Message.new("payload", "message", :base64 => true)
      end

      it "should set base64 to false after decoding" do
        SSL.expects(:base64_decode).with("payload")
        m = Message.new("payload", "message", :base64 => true)
        m.base64?.should == false
      end
    end

    describe "#base64_encode" do
      it "should not encode already encoded messages" do
        SSL.expects(:base64_encode).never
        Message.any_instance.stubs(:base64_decode!)
        m = Message.new("payload", "message", :base64 => true)
        m.base64_encode!
      end

      it "should encode plain messages" do
        SSL.expects(:base64_encode).with("payload")
        m = Message.new("payload", "message")
        m.base64_encode!
      end

      it "should set base64 to false after encoding" do
        SSL.expects(:base64_encode)
        m = Message.new("payload", "message")
        m.base64_encode!
        m.base64?.should == true
      end
    end

    describe "#base64?" do
      it "should correctly report base64 state" do
        m = Message.new("payload", "message")
        m.base64?.should == m.instance_variable_get("@base64")
      end
    end

    describe "#type=" do
      it "should only allow types to be set when discovered hosts were given" do
        m = Message.new("payload", "message")
        Config.instance.instance_variable_set("@direct_addressing", true)

        expect {
          m.type = :direct_request
        }.to raise_error("Can only set type to :direct_request if discovered_hosts have been set")
      end

      it "should not allow direct_request to be set if direct addressing isnt enabled" do
        m = Message.new("payload", "message")
        Config.instance.instance_variable_set("@direct_addressing", false)

        expect {
          m.type = :direct_request
        }.to raise_error("Direct requests is not enabled using the direct_addressing config option")
      end

      it "should only accept valid types" do
        m = Message.new("payload", "message")
        Config.instance.instance_variable_set("@direct_addressing", true)

        expect {
          m.type = :foo
        }.to raise_error("Unknown message type foo")
      end

      it "should set the type" do
        m = Message.new("payload", "message")
        m.type = :request
        m.type.should == :request
      end
    end

    describe "#encode!" do
      it "should encode replies using the security plugin #encodereply" do
        request = mock
        request.stubs(:agent).returns("rspec_agent")
        request.stubs(:collective).returns("collective")
        request.stubs(:payload).returns({:requestid => "123", :callerid => "id=callerid"})

        security = mock
        security.expects(:encodereply).with('rspec_agent', 'payload', '123', 'id=callerid')
        security.expects(:valid_callerid?).with("id=callerid").returns(true)

        PluginManager.expects("[]").with("security_plugin").returns(security).twice

        m = Message.new("payload", "message", :request => request, :type => :reply)

        m.encode!
      end

      it "should encode requests using the security plugin #encoderequest" do
        security = mock
        security.expects(:encoderequest).with("identity", 'payload', '123', Util.empty_filter, 'rspec_agent', 'mcollective', 60).twice
        PluginManager.expects("[]").with("security_plugin").returns(security).twice

        Config.any_instance.expects(:identity).returns("identity").times(4)

        Message.any_instance.expects(:requestid).returns("123").twice

        m = Message.new("payload", "message", :type => :request, :agent => "rspec_agent", :collective => "mcollective")
        m.encode!

        m = Message.new("payload", "message", :type => :direct_request, :agent => "rspec_agent", :collective => "mcollective")
        m.encode!
      end

      it "should not allow bad callerids when replying" do
        request = mock
        request.stubs(:agent).returns("rspec_agent")
        request.stubs(:collective).returns("collective")
        request.stubs(:payload).returns({:requestid => "123", :callerid => "caller/id"})

        security = mock
        security.expects(:valid_callerid?).with("caller/id").returns(false)
        PluginManager.expects("[]").with("security_plugin").returns(security)

        m = Message.new("payload", "message", :request => request, :type => :reply)

        expect {
          m.encode!
        }.to raise_error('callerid in original request is not valid, surpressing reply to potentially forged request')
      end
    end

    describe "#decode!" do
      it "should check for valid types" do
        expect {
          m = Message.new("payload", "message", :type => :foo)
          m.decode!
        }.to raise_error("Cannot decode message type foo")
      end

      it "should set state based on decoded message" do
        msg = mock
        msg.stubs(:include?).returns(true)
        msg.stubs("[]").with(:collective).returns("collective")
        msg.stubs("[]").with(:agent).returns("rspecagent")
        msg.stubs("[]").with(:filter).returns("filter")
        msg.stubs("[]").with(:requestid).returns("1234")
        msg.stubs("[]").with(:ttl).returns(30)
        msg.stubs("[]").with(:msgtime).returns(1314628987)

        security = mock
        security.expects(:decodemsg).returns(msg)
        PluginManager.expects("[]").with("security_plugin").returns(security)

        m = Message.new(msg, "message", :type => :reply)
        m.decode!

        m.collective.should == "collective"
        m.agent.should == "rspecagent"
        m.filter.should == "filter"
        m.requestid.should == "1234"
        m.ttl.should == 30
      end

      it "should not allow bad callerids from the security plugin on requests" do
        security = mock
        security.expects(:decodemsg).returns({:callerid => "foo/bar"})
        security.expects(:valid_callerid?).with("foo/bar").returns(false)

        PluginManager.expects("[]").with("security_plugin").returns(security).twice

        m = Message.new("payload", "message", :type => :request)

        expect {
          m.decode!
        }.to raise_error('callerid in request is not valid, surpressing reply to potentially forged request')
      end
    end

    describe "#validate" do
      it "should only validate requests" do
        m = Message.new("msg", "message", :type => :reply)
        expect {
          m.validate
        }.to raise_error("Can only validate request messages")
      end

      it "should raise an exception for incorrect messages" do
        sec = mock
        sec.expects("validate_filter?").returns(false)
        PluginManager.expects("[]").with("security_plugin").returns(sec)

        payload = mock
        payload.expects("[]").with(:filter).returns({})

        m = Message.new(payload, "message", :type => :request)
        m.instance_variable_set("@msgtime", Time.now.to_i)

        expect {
          m.validate
        }.to raise_error(NotTargettedAtUs)
      end

      it "should pass for good messages" do
        sec = mock
        sec.expects(:validate_filter?).returns(true)
        PluginManager.expects("[]").returns(sec)

        payload = mock
        payload.expects("[]").with(:filter).returns({})
        m = Message.new(payload, "message", :type => :request)
        m.instance_variable_set("@msgtime", Time.now.to_i)
        m.validate
      end

      it "should set the @validated property" do
        sec = mock
        sec.expects(:validate_filter?).returns(true)
        PluginManager.expects("[]").returns(sec)

        payload = mock
        payload.expects("[]").with(:filter).returns({})
        m = Message.new(payload, "message", :type => :request)
        m.instance_variable_set("@msgtime", Time.now.to_i)

        m.validated.should == false
        m.validate
        m.validated.should == true
      end

      it "should not validate for messages older than TTL" do
        stats = mock
        stats.expects(:ttlexpired).once

        MCollective::PluginManager << {:type => "global_stats", :class => stats}

        m = Message.new({:callerid => "caller", :senderid => "sender"}, "message", :type => :request)
        m.instance_variable_set("@msgtime", (Time.now.to_i - 120))

        expect {
          m.validate
        }.to raise_error(MsgTTLExpired)
      end
    end

    describe "#publish" do
      it "should publish itself to the connector" do
        m = Message.new("msg", "message", :type => :request)

        connector = mock
        connector.expects(:publish).with(m)
        PluginManager.expects("[]").returns(connector)

        m.publish
      end

      it "should support direct addressing" do
        m = Message.new("msg", "message", :type => :request)
        m.discovered_hosts = ["one", "two", "three"]

        Config.any_instance.expects(:direct_addressing).returns(true)
        Config.any_instance.expects(:direct_addressing_threshold).returns(10)

        connector = mock
        connector.expects(:publish).with(m)
        PluginManager.expects("[]").returns(connector)

        m.publish
        m.type.should == :direct_request
      end

      it "should only direct publish below the configured threshold" do
        m = Message.new("msg", "message", :type => :request)
        m.discovered_hosts = ["one", "two", "three"]

        Config.any_instance.expects(:direct_addressing).returns(true)
        Config.any_instance.expects(:direct_addressing_threshold).returns(1)

        connector = mock
        connector.expects(:publish).with(m)
        PluginManager.expects("[]").returns(connector)

        m.publish
        m.type.should == :request
      end
    end

    describe "#create_reqid" do
      it "should create a valid request id" do
        m = Message.new("msg", "message", :agent => "rspec", :collective => "mc")

        Config.any_instance.expects(:identity).returns("rspec")
        Time.expects(:now).returns(1.1)

        Digest::MD5.expects(:hexdigest).with("rspec-1.1-rspec-mc").returns("reqid")

        m.create_reqid.should == "reqid"
      end
    end
  end
end
