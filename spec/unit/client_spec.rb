#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Client do
    describe "#timeout_for_compound_filter" do
      it "should return the correct time" do
        security = mock
        security.expects(:initiated_by=)
        connector = mock
        connector.expects(:connect)
        ddl = mock
        ddl.stubs(:meta).returns({:timeout => 1})

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
