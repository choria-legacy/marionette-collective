#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe PluginManager do
    before do
      class MCollective::Foo; end

      PluginManager.pluginlist.each {|p| PluginManager.delete p}
    end

    describe "#<<" do
      it "should store a plugin by name" do
        PluginManager << {:type => "foo", :class => "MCollective::Foo"}
        PluginManager.instance_variable_get("@plugins").include?("foo").should == true
      end

      it "should store a plugin instance" do
        f = MCollective::Foo.new

        PluginManager << {:type => "foo", :class => f}
        PluginManager.instance_variable_get("@plugins")["foo"][:instance].object_id.should == f.object_id
      end

      it "should detect duplicate plugins" do
        PluginManager << {:type => "foo", :class => "MCollective::Foo"}

        expect {
          PluginManager << {:type => "foo", :class => "MCollective::Foo"}
        }.to raise_error("Plugin foo already loaded")
      end

      it "should store single instance preference correctly" do
        PluginManager << {:type => "foo", :class => "MCollective::Foo", :single_instance => false}
        PluginManager.instance_variable_get("@plugins")["foo"][:single].should == false
      end

      it "should always set single to true when supplied an instance" do
        PluginManager << {:type => "foo", :class => MCollective::Foo.new, :single_instance => false}
        PluginManager.instance_variable_get("@plugins")["foo"][:single].should == true
      end
    end

    describe "#delete" do
      it "should remove plugins" do
        PluginManager << {:type => "foo", :class => MCollective::Foo.new}
        PluginManager.instance_variable_get("@plugins").include?("foo").should == true
        PluginManager.delete("foo")
        PluginManager.instance_variable_get("@plugins").include?("foo").should == false
      end
    end

    describe "#include?" do
      it "should correctly check if plugins were added" do
        PluginManager << {:type => "foo", :class => MCollective::Foo.new}
        PluginManager.include?("foo").should == true
        PluginManager.include?("bar").should == false
      end
    end

    describe "#pluginlist" do
      it "should return the correct list of plugins" do
        PluginManager << {:type => "foo", :class => MCollective::Foo.new}
        PluginManager << {:type => "bar", :class => MCollective::Foo.new}

        PluginManager.pluginlist.sort.should == ["bar", "foo"]
      end
    end

    describe "#[]" do
      it "should detect if the requested plugin does not exist" do
        expect {
          PluginManager["foo"]
        }.to raise_error("No plugin foo defined")
      end

      it "should create new instances on demand" do
        PluginManager << {:type => "foo", :class => "MCollective::Foo"}
        PluginManager["foo"].class.should == MCollective::Foo
      end

      it "should return the cached instance" do
        f = MCollective::Foo.new

        PluginManager << {:type => "foo", :class => f}
        PluginManager["foo"].object_id.should == f.object_id
      end

      it "should create new instances on every request if requested" do
        PluginManager << {:type => "foo", :class => "MCollective::Foo", :single_instance => false}
        PluginManager["foo"].object_id.should_not == PluginManager["foo"].object_id
      end
    end

    describe "#loadclass" do
      it "should load the correct filename given a ruby class name" do
        PluginManager.stubs(:load).with("mcollective/foo.rb").once
        PluginManager.loadclass("MCollective::Foo")
      end

      it "should raise errors for load errors" do
        PluginManager.stubs(:load).raises("load failure")
        Log.expects(:error)
        expect { PluginManager.loadclass("foo") }.to raise_error(/load failure/)
      end

      it "should support squashing load errors" do
        PluginManager.stubs(:load).raises("load failure")
        Log.expects(:error)
        PluginManager.loadclass("foo", true)
      end
    end

    describe "#grep" do
      it "should return matching plugins from the list" do
        PluginManager << {:type => "foo", :class => MCollective::Foo.new}
        PluginManager << {:type => "bar", :class => MCollective::Foo.new}

        PluginManager.grep(/oo/).should == ["foo"]
      end
    end
  end
end
