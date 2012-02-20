#!/usr/bin/env rspec

require 'spec_helper'

module MCollective::Facts
  describe Base do
    before do
      class Testfacts<Base; end

      MCollective::PluginManager.delete("facts_plugin")
      MCollective::PluginManager << {:type => "facts_plugin", :class => "MCollective::Facts::Testfacts"}
    end

    describe "#inherited" do
      it "should add classes to the plugin manager" do
        MCollective::PluginManager.stubs("<<").with({:type => "facts_plugin", :class => "MCollective::Facts::Bar"})

        class Bar<Base; end
      end

      it "should be available in the PluginManager" do
        MCollective::PluginManager["facts_plugin"].class.should == MCollective::Facts::Testfacts
      end
    end

    describe "#get_fact" do
      it "should call the fact provider #load_facts_from_source" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar"}).once

        f = Testfacts.new
        f.get_fact("foo")
      end

      it "should honor the cache timeout" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar"}).once

        f = Testfacts.new
        f.get_fact("foo")
        f.get_fact("foo")
      end

      it "should detect empty facts" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({})
        MCollective::Log.expects("error").with("Failed to load facts: RuntimeError: Got empty facts").once

        f = Testfacts.new
        f.get_fact("foo")
      end

      it "should convert non string facts to strings" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({:foo => "bar"})

        f = Testfacts.new
        f.get_fact("foo").should == "bar"
      end

      it "should not create duplicate facts while converting to strings" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({:foo => "bar"})

        f = Testfacts.new
        f.get_fact(nil).include?(:foo).should == false
      end

      it "should update last_facts_load on success" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar"}).once

        f = Testfacts.new
        f.get_fact("foo")

        f.instance_variable_get("@last_facts_load").should_not == 0
      end

      it "should restore last known good facts on failure" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({}).once
        MCollective::Log.expects("error").with("Failed to load facts: RuntimeError: Got empty facts").once

        f = Testfacts.new
        f.instance_variable_set("@last_good_facts", {"foo" => "bar"})

        f.get_fact("foo").should == "bar"
      end

      it "should return all facts for nil parameter" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar", "bar" => "baz"})

        f = Testfacts.new
        f.get_fact(nil).keys.size.should == 2
      end

      it "should return a specific fact when specified" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar", "bar" => "baz"})

        f = Testfacts.new
        f.get_fact("bar").should == "baz"
      end
    end

    describe "#get_facts" do
      it "should load and return all facts" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar", "bar" => "baz"})

        f = Testfacts.new
        f.get_facts.should == {"foo" => "bar", "bar" => "baz"}
      end
    end

    describe "#has_fact?" do
      it "should correctly report fact presense" do
        Testfacts.any_instance.stubs("load_facts_from_source").returns({"foo" => "bar"})

        f = Testfacts.new
        f.has_fact?("foo").should == true
        f.has_fact?("bar").should == false
      end
    end

  end
end
