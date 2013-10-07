#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module PluginPackager
    describe StandardDefinition do

      let(:configuration) do
        {:target      => '.',
         :pluginname  => 'test-package',
         :revision    => nil,
         :preinstall  => nil,
         :postinstall => nil,
         :version     => nil,
         :mcname      => nil,
         :mcversion   => nil
        }
      end

      before :each do
        PluginPackager.expects(:get_metadata).once.returns({:name => "foo", :version => 1})
      end

      describe "#initialize" do
        it "should replace whitespaces in the package name with dashes" do
          configuration[:pluginname] = 'test   plugin'
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.metadata[:name].should == "test-plugin"
        end

        it "should set the version if passed from the config hash" do
          configuration[:version] = '1.2.3'
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.metadata[:version].should == '1.2.3'
        end

        it "should set dependencies if present" do
          configuration[:dependency] = [{:name => "foo", :version => nil}]
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.dependencies.should == [{:name => "foo", :version => nil},
                                         {:name => "mcollective-common", :version => nil}]
        end

        it "should set mc name and version dependencies" do
          plugin = StandardDefinition.new(configuration, {:mcname => "pe-mcollective", :mcversion => "1"}, "testplugin")
          plugin.mcname.should == "pe-mcollective"
          plugin.mcversion.should == "1"
        end

        it "should replace underscores with dashes in the name" do
          configuration[:pluginname] = 'test_plugin'
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.metadata[:name].should == "test-plugin"
        end
      end

      describe "#identify_packages" do
        it "should attempt to identify all packages" do
          StandardDefinition.any_instance.expects(:common).once.returns(:check)
          StandardDefinition.any_instance.expects(:plugin).once.returns(:check)

          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.packagedata[:common].should == :check
          plugin.packagedata[:testplugin].should == :check
        end
      end

      describe "#plugin" do

        it "should return nil if the plugin doesn't contain any files" do
          StandardDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(false)
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.packagedata[:testplugin].should == nil
        end

        it "should add plugin files to the file list" do
          StandardDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./testplugin/*").returns(["file.rb"])
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.packagedata[:testplugin][:files].should == ["file.rb"]
        end

        it "should add common package as dependency if present" do
          configuration[:pluginname] = 'foo'
          StandardDefinition.any_instance.expects(:common).returns(true)
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./testplugin/*").returns(["file.rb"])
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.packagedata[:testplugin][:files].should == ["file.rb"]
          plugin.packagedata[:testplugin][:dependencies].should == [{:name => "mcollective-common", :version => nil}]
          plugin.packagedata[:testplugin][:plugindependency].should == {:name => "mcollective-foo-common", :version => 1, :revision => 1}
        end
      end

      describe "#common" do
        before do
          StandardDefinition.any_instance.expects(:plugin).returns(false)
        end

        it "should return nil if common doesn't contain any files" do
          PluginPackager.expects(:check_dir_present).returns(false)
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.packagedata[:common].should == nil
        end

        it "should add common files to the file list" do
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./util/*").returns(["common.rb"])
          plugin = StandardDefinition.new(configuration, {}, "testplugin")
          plugin.packagedata[:common][:files].should == ["common.rb"]
        end
      end
    end
  end
end
