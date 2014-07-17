#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Connector
    describe "base" do

      before :each do
        Base.unstub(:inherited)
      end

      it "should fail if the ddl isn't valid" do
        PluginManager.expects(:<<).never

        expect {
          class TestConnectorA<Connector::Base;end
        }.to raise_error RuntimeError
      end

      it "should load the ddl and add the connector to the PluginManager" do
        DDL.stubs(:new)
        class TestConnectorB<Connector::Base;end
        PluginManager["connector_plugin"].class.should == MCollective::Connector::TestConnectorB
      end
    end
  end
end
