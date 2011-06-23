#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Message do
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
                m.options.should == false
                m.discovered_hosts.should == nil
            end

            it "should set all supplied options" do
                Message.any_instance.expects(:base64_decode!)

                m = Message.new("payload", "message", :base64 => true,
                                                      :agent => "rspecagent",
                                                      :headers => {:rspec => "test"},
                                                      :type => :rspec,
                                                      :filter => "filter",
                                                      :options => "options",
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
                m.options.should == "options"
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
                SSL.expects(:base64_decode)
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
                SSL.expects(:base64_encode)
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

        describe "#encode!" do
            it "should encode replies using the security plugin #encodereply" do
                request = mock
                request.stubs(:agent).returns("rspec_agent")
                request.stubs(:collective).returns("collective")
                request.stubs(:payload).returns({:requestid => "123", :callerid => "callerid"})

                security = mock
                security.expects(:encodereply).with('rspec_agent', 'payload', '123', 'callerid')

                PluginManager.expects("[]").with("security_plugin").returns(security)


                m = Message.new("payload", "message", :request => request, :type => :reply)

                m.encode!
            end

            it "should encode requests using the security plugin #encoderequest" do
                security = mock
                security.expects(:encoderequest).with("identity", 'payload', '123', Util.empty_filter, 'rspec_agent', 'mcollective')
                PluginManager.expects("[]").with("security_plugin").returns(security)

                Config.any_instance.expects(:identity).returns("identity").twice

                Message.any_instance.expects(:requestid).returns("123")

                m = Message.new("payload", "message", :type => :request, :agent => "rspec_agent", :collective => "mcollective")

                m.encode!
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

                security = mock
                security.expects(:decodemsg).returns(msg)
                PluginManager.expects("[]").with("security_plugin").returns(security)

                m = Message.new(msg, "message", :type => :reply)
                m.decode!

                m.collective.should == "collective"
                m.agent.should == "rspecagent"
                m.filter.should == "filter"
                m.requestid.should == "1234"
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
                m.validate
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
