#! /usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Generators
      describe AgentGenerator do

        describe "#create_ddl" do

          before :each do
            AgentGenerator.any_instance.stubs(:create_plugin_content)
            AgentGenerator.any_instance.stubs(:create_plugin_string)
            AgentGenerator.any_instance.stubs(:write_plugins)
            AgentGenerator.any_instance.expects(:create_metadata_string).returns("metadata\n")
          end

          it "should create a ddl with nothing but metadata if no actions are specified" do
            result = AgentGenerator.new("foo").ddl
            result.should == "metadata\n"
          end

          it "should add action strings to metadata if there are actions specfied" do
            result = AgentGenerator.new("foo", ["action1", "action2"]).ddl
            expected = File.read(File.join(File.dirname(__FILE__), "snippets", "agent_ddl"))
            result.should == expected
          end
        end

        describe "#create_plugin_content" do
          before :each do
            AgentGenerator.any_instance.stubs(:create_plugin_string)
            AgentGenerator.any_instance.stubs(:write_plugins)
            AgentGenerator.any_instance.stubs(:create_metadata_string).returns("metadata\n")
            AgentGenerator.any_instance.stubs(:create_ddl)
          end

          it "should create the correct pluginf ile content with actions if they are specified" do
            AgentGenerator.any_instance.stubs(:create_metadata_string).returns("meta\n")
            result = AgentGenerator.new("foo", ["action1", "action2"]).content
            result.should == "      action \"action1\" do\n      end\n\n      action \"action2\" do\n      end\n"
          end
        end

        describe "#action_help" do
          before :each do
            AgentGenerator.any_instance.stubs(:create_plugin_content)
            AgentGenerator.any_instance.stubs(:create_plugin_string)
            AgentGenerator.any_instance.stubs(:write_plugins)
            AgentGenerator.any_instance.stubs(:create_metadata_string).returns("metadata\n")
          end

          it "should load and return the action_help snippet" do
            erb = mock
            erb.stubs(:result).returns("result")
            File.stubs(:dirname).returns("/tmp")
            File.expects(:read).with("/tmp/templates/action_snippet.erb").returns("result")
            ERB.expects(:new).with("result").returns(erb)
            AgentGenerator.new("foo", ["action"])
          end

          it "should raise an error if the action_help snippet does not exist" do
            File.stubs(:dirname).returns("/tmp")
            File.stubs(:read).raises(Errno::ENOENT, "No such file or directory")
            expect{
              AgentGenerator.new("foo", ["action"])
            }.to raise_error Errno::ENOENT
          end
        end
      end
  end
end
