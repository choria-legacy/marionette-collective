#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Client do
    describe "#discover" do
      before do
        @security = mock
        @security.expects(:initiated_by=)
        @connector = mock
        @connector.expects(:connect)
        @ddl = mock
        @ddl.stubs(:meta).returns({:timeout => 1})
        @discoverer = mock

        Discovery.expects(:new).returns(@discoverer)

        Config.instance.instance_variable_set("@configured", true)
        PluginManager.expects("[]").with("connector_plugin").returns(@connector)
        PluginManager.expects("[]").with("security_plugin").returns(@security)

        @client = Client.new("/nonexisting")
      end

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
