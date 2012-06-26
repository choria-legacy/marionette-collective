#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Client do
    before do
      @security = mock
      @security.stubs(:initiated_by=)
      @connector = mock
      @connector.stubs(:connect)
      @connector.stubs(:subscribe)
      @connector.stubs(:unsubscribe)
      @ddl = mock
      @ddl.stubs(:meta).returns({:timeout => 1})
      @discoverer = mock

      Discovery.expects(:new).returns(@discoverer)

      Config.instance.instance_variable_set("@configured", true)
      PluginManager.expects("[]").with("connector_plugin").returns(@connector)
      PluginManager.expects("[]").with("security_plugin").returns(@security)

      @client = Client.new("/nonexisting")
      @client.options = Util.default_options
    end

    describe "#sendreq" do
      it "should send the supplied message" do
        message = Message.new("rspec", nil, {:agent => "rspec", :type => :request, :collective => "mcollective", :filter => Util.empty_filter, :options => Util.default_options})

        message.expects(:encode!)
        @client.expects(:subscribe).with("rspec", :reply)
        message.expects(:publish)
        message.expects(:requestid).twice
        @client.sendreq(message, "rspec")
      end

      it "should not subscribe to a reply queue for a message with a reply-to" do
        message = Message.new("rspec", nil, {:agent => "rspec", :type => :request, :collective => "mcollective", :filter => Util.empty_filter, :options => Util.default_options})
        message.reply_to = "rspec"

        message.expects(:encode!)
        @client.expects(:subscribe).never
        message.expects(:publish)
        message.expects(:requestid).twice
        @client.sendreq(message, "rspec")
      end
    end
    describe "#req" do
      it "should record the requestid" do
        message = Message.new("rspec", nil, {:agent => "rspec", :type => :request, :collective => "mcollective", :filter => Util.empty_filter, :options => Util.default_options})
        message.discovered_hosts = ["rspec"]

        reply = mock
        reply.stubs("payload").returns("rspec payload")

        @client.expects(:sendreq).returns("823a3419a0975c3facbde121f72ab61f")
        @client.expects(:receive).returns(reply)

        Time.stubs(:now).returns(Time.at(1340621250), Time.at(1340621251))

        @client.req(message){}.should == {:blocktime => 1.0, :discoverytime => 0, :noresponsefrom => [],
                                          :requestid => "823a3419a0975c3facbde121f72ab61f", :responses => 1,
                                          :starttime => 1340621250.0, :totaltime => 1.0}
      end
    end

    describe "#discover" do
      it "should not allow non integer limits" do
        expect { @client.discover(nil, nil, 1.1) }.to raise_error("Limit has to be an integer")
      end

      it "should calculate the correct timeout" do
        @client.expects(:timeout_for_compound_filter).returns(1)
        @client.options = {:filter => {"compound" => {}}}
        @discoverer.expects(:discover).with({}, 2, 0).returns([])
        @client.discover({}, 1)
      end
    end

    describe "#timeout_for_compound_filter" do
      it "should return the correct time" do
        security = mock
        security.expects(:initiated_by=)
        connector = mock
        connector.expects(:connect)
        ddl = mock
        ddl.stubs(:meta).returns({:timeout => 1})
        Discovery.expects(:new).returns(nil)

        Config.instance.instance_variable_set("@configured", true)
        PluginManager.expects("[]").with("connector_plugin").returns(connector)
        PluginManager.expects("[]").with("security_plugin").returns(security)

        client = Client.new("/nonexisting")

        filter = [Matcher.create_compound_callstack("test().size=1 and rspec().size=1")]

        DDL.expects(:new).with("test_data", :data).returns(ddl)
        DDL.expects(:new).with("rspec_data", :data).returns(ddl)

        client.timeout_for_compound_filter(filter).should == 2
      end
    end
  end
end
