#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/application/plugin'

module MCollective
  class Application
    describe Plugin do

      let(:ddl) { mock }

      before do
        @app = MCollective::Application::Plugin.new()
        @app.configuration[:rpctemplate] = "rspec-helptemplate.erb"
      end

      describe "#doc_command" do
        it "should display doc output for a plugin that exists when using 'plugin'" do
          @app.configuration[:target] = "rspec"
          PluginManager.stubs(:find).with(:agent, "ddl").returns(["rspec"])
          PluginManager.stubs(:find).with(:aggregate, "ddl").returns([""])
          PluginManager.stubs(:find).with(:data, "ddl").returns([""])
          PluginManager.stubs(:find).with(:discovery, "ddl").returns([""])
          PluginManager.stubs(:find).with(:validator, "ddl").returns([""])
          PluginManager.stubs(:find).with(:connector, "ddl").returns([""])
          @app.stubs(:load_plugin_ddl).with('rspec', :agent).returns(ddl)
          ddl.expects(:help).with("rspec-helptemplate.erb").returns("agent_template")
          @app.expects(:puts).with("agent_template")
          @app.doc_command
        end

        it "should display doc output for a plugin that exists when using 'plugintype/plugin'" do
          @app.configuration[:target] = "agent/rspec"
          @app.stubs(:load_plugin_ddl).with(:rspec, "agent").returns(ddl)
          ddl.expects(:help).with("rspec-helptemplate.erb").returns("agent_template")
          @app.expects(:puts).with("agent_template")
          @app.doc_command
        end

        it "should display a failure message for a plugin that doesn't exist when using 'plugin'" do
          @app.configuration[:target] = "rspec"
          PluginManager.stubs(:find).returns([""])
          @app.expects(:abort).with("Could not find a plugin named 'rspec' in any supported plugin type").raises("test_error")

          expect{
            @app.doc_command
          }.to raise_error "test_error"
        end

        it "should display a failure message for a plugin that doens't exist when using 'plugintype/plugin'" do
          @app.configuration[:target] = "agent/rspec"
          @app.expects(:load_plugin_ddl).with(:rspec, "agent").returns(nil)
          @app.expects(:abort).with("Could not find a 'agent' plugin named 'rspec'").raises("test_error")

          expect{
            @app.doc_command
          }.to raise_error "test_error"
        end

        it "should display a failure message if duplicate plugins are found" do
          @app.configuration[:target] = "rspec"
          PluginManager.stubs(:find).returns(["rspec"])
          @app.stubs(:abort).with("Duplicate plugin name found, please specify a full path like agent/rpcutil").raises("test_error")

          expect{
            @app.doc_command
          }.to raise_error "test_error"
        end

        it "should display a failure message for a plugintype that doens't exist" do
          @app.configuration[:target] = "foo/rspec"
          @app.stubs(:load_plugin_ddl).with(:rspec, "foo").returns(nil)
          @app.stubs(:abort).with("Could not find a 'foo' plugin named 'rspec'").raises("test_error")

          expect{
            @app.doc_command
          }.to raise_error "test_error"
        end
     end
    end
  end
end
