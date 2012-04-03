#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module PluginPackager
    describe StandardDefinition do
      before :each do
        PluginPackager.expects(:get_metadata).once.returns({:name => "foo"})
      end

      it "should replace spaces in the package name with underscores" do
        plugin = StandardDefinition.new(".", "test plugin", nil, nil, nil, :fooplugin)
        plugin.metadata[:name].should == "test_plugin"
      end

      describe "#identify_packages" do
        it "should attempt to identify all packages" do
          StandardDefinition.any_instance.expects(:common).once.returns(:check)
          StandardDefinition.any_instance.expects(:plugin).once.returns(:check)

          plugin = StandardDefinition.new(".", nil, nil, nil, nil, :fooplugin)
          plugin.packagedata[:common].should == :check
          plugin.packagedata[:fooplugin].should == :check
        end
      end

      describe "#plugin" do

        it "should return nil if the plugin doesn't contain any files" do
          StandardDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(false)
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, :fooplugin)
          plugin.packagedata[:fooplugin].should == nil
        end

        it "should add plugin files to the file list" do
          StandardDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./fooplugin/*").returns(["file.rb"])
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, :fooplugin)
          plugin.packagedata[:fooplugin][:files].should == ["file.rb"]
        end

        it "should add common package as dependency if present" do
          StandardDefinition.any_instance.expects(:common).returns(true)
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./fooplugin/*").returns(["file.rb"])
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, :fooplugin)
          plugin.packagedata[:fooplugin][:files].should == ["file.rb"]
          plugin.packagedata[:fooplugin][:dependencies].should == ["mcollective", "mcollective-foo-common"]
        end
      end

      describe "#common" do
        before do
          StandardDefinition.any_instance.expects(:plugin).returns(false)
        end

        it "should return nil if common doesn't contain any files" do
          PluginPackager.expects(:check_dir_present).returns(false)
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, :fooplugin)
          plugin.packagedata[:common].should == nil
        end

        it "should add common files to the file list" do
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./util/*").returns(["common.rb"])
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, :fooplugin)
          plugin.packagedata[:common][:files].should == ["common.rb"]
        end
      end
    end
  end
end
