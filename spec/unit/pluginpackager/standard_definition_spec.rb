#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module PluginPackager
    describe StandardDefinition do
      before :each do
        PluginPackager.expects(:get_metadata).once.returns({:name => "foo", :version => 1})
      end

      describe "#initialize" do
        it "should replace spaces in the package name with dashes" do
          plugin = StandardDefinition.new(".", "test plugin", nil, nil, nil, nil, [], {}, "testplugin")
          plugin.metadata[:name].should == "test-plugin"
        end

        it "should set dependencies if present" do
          plugin = StandardDefinition.new(".", "test plugin", nil, nil, nil, nil, [{:name => "foo", :version => nil}], {}, "testplugin")
          plugin.dependencies.should == [{:name => "foo", :version => nil},
                                         {:name => "mcollective-common", :version => nil}]
        end

        it "should set mc name and version dependencies" do
          plugin = StandardDefinition.new(".", "test plugin", nil, nil, nil, nil, [], {:mcname => "pe-mcollective", :mcversion => "1"}, "testplugin")
          plugin.mcname.should == "pe-mcollective"
          plugin.mcversion.should == "1"
        end

        it "should replace underscores with dashes in the name" do
          plugin = StandardDefinition.new(".", "test_plugin", nil, nil, nil, nil, [], {:mcname => "pe-mcollective", :mcversion => "1"}, "testplugin")
          plugin.metadata[:name].should == "test-plugin"
        end

        it "should replace whitespaces with a single dash in the name" do
          plugin = StandardDefinition.new(".", "test  plugin", nil, nil, nil, nil, [], {:mcname => "pe-mcollective", :mcversion => "1"}, "testplugin")
          plugin.metadata[:name].should == "test-plugin"
        end
      end

      describe "#identify_packages" do
        it "should attempt to identify all packages" do
          StandardDefinition.any_instance.expects(:common).once.returns(:check)
          StandardDefinition.any_instance.expects(:plugin).once.returns(:check)

          plugin = StandardDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "testplugin")
          plugin.packagedata[:common].should == :check
          plugin.packagedata["testplugin"].should == :check
        end
      end

      describe "#plugin" do

        it "should return nil if the plugin doesn't contain any files" do
          StandardDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(false)
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "testplugin")
          plugin.packagedata["testplugin"].should == nil
        end

        it "should add plugin files to the file list" do
          StandardDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./testplugin/*").returns(["file.rb"])
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "testplugin")
          plugin.packagedata["testplugin"][:files].should == ["file.rb"]
        end

        it "should add common package as dependency if present" do
          StandardDefinition.any_instance.expects(:common).returns(true)
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./testplugin/*").returns(["file.rb"])
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "testplugin")
          plugin.packagedata["testplugin"][:files].should == ["file.rb"]
          plugin.packagedata["testplugin"][:dependencies].should == [{:name => "mcollective-common", :version => nil}]
          plugin.packagedata["testplugin"][:plugindependency].should == {:name => "mcollective-foo-common", :version => 1, :iteration => 1}
        end
      end

      describe "#common" do
        before do
          StandardDefinition.any_instance.expects(:plugin).returns(false)
        end

        it "should return nil if common doesn't contain any files" do
          PluginPackager.expects(:check_dir_present).returns(false)
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "testplugin")
          plugin.packagedata[:common].should == nil
        end

        it "should add common files to the file list" do
          PluginPackager.expects(:check_dir_present).returns(true)
          Dir.expects(:glob).with("./util/*").returns(["common.rb"])
          plugin = StandardDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "testplugin")
          plugin.packagedata[:common][:files].should == ["common.rb"]
        end
      end
    end
  end
end
