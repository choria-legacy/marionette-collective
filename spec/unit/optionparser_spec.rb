#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Optionparser do
    describe "#initialize" do
      it "should store the included list as an array" do
        parser = Optionparser.new({}, "included")
        parser.instance_variable_get("@include").should == ["included"]

        parser = Optionparser.new({}, ["included"])
        parser.instance_variable_get("@include").should == ["included"]
      end

      it "should store the excluded list as an array" do
        parser = Optionparser.new({}, "", "excluded")
        parser.instance_variable_get("@exclude").should == ["excluded"]

        parser = Optionparser.new({}, "", ["excluded"])
        parser.instance_variable_get("@exclude").should == ["excluded"]
      end

      it "should gather default options" do
        Util.expects(:default_options).returns({})
        Optionparser.new({})
      end

      it "should merge supplied options with defaults" do
        defaults = {}
        supplied = {}

        Util.expects(:default_options).returns(defaults)
        defaults.expects(:merge!).with(supplied)

        Optionparser.new(supplied)
      end
    end

    describe "#parse" do
      it "should yield to the caller" do
        parser = Optionparser.new(defaults={:default => 1})

        block_ran = false

        parser.parse do |p, o|
          p.class.should == OptionParser
          o.should == Util.default_options.merge(defaults)
          block_ran = true
        end

        block_ran.should == true
      end

      it "should add required options" do
        parser = Optionparser.new(defaults={:default => 1})
        parser.expects(:add_required_options)
        parser.parse
      end

      it "should optionally add common options" do
        parser = Optionparser.new(defaults={:default => 1})
        parser.stubs(:add_required_options)
        parser.expects(:add_common_options)
        parser.parse

        parser = Optionparser.new(defaults={:default => 1}, "", "common")
        parser.stubs(:add_required_options)
        parser.expects(:add_common_options).never
        parser.parse
      end

      it "should support adding arbitrary named sections of options" do
        parser = Optionparser.new(defaults={:default => 1}, "filter")
        parser.stubs(:add_required_options)
        parser.stubs(:add_common_options)
        parser.expects(:add_filter_options)
        parser.parse
      end

      it "should support excluding sections that was specifically included" do
        parser = Optionparser.new(defaults={:default => 1}, "filter", "filter")
        parser.stubs(:add_required_options)
        parser.stubs(:add_common_options)
        parser.expects(:add_filter_options).never
        parser.parse
      end

      it "should parse MCOLLECTIVE_EXTRA_OPTS" do
        ENV["MCOLLECTIVE_EXTRA_OPTS"] = "--dt 999"
        @parser = Optionparser.new
        @parser.parse[:disctimeout].should == 999
        ENV.delete("MCOLLECTIVE_EXTRA_OPTS")
      end

      it "should not set the active collective from the config class if given on the cli" do
        parser = Optionparser.new(defaults={:collective => "rspec"})
        parser.stubs(:add_required_options)
        parser.stubs(:add_common_options)
        Config.any_instance.expects(:main_collective).never
        parser.parse
      end

      it "should set the active collective from the config class if not given on the cli" do
        parser = Optionparser.new(defaults={})
        parser.stubs(:add_required_options)
        parser.stubs(:add_common_options)
        Config.any_instance.expects(:main_collective).returns(:rspec).once
        parser.parse[:collective].should == :rspec
      end
    end
  end
end
