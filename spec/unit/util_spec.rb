#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Util do
    before do
      class MCollective::Connector::Stomp<MCollective::Connector::Base; end

      PluginManager.clear
      PluginManager << {:type => "connector_plugin", :class => MCollective::Connector::Stomp.new}
    end

    describe "#windows?" do
      it "should correctly detect windows on unix platforms" do
        RbConfig::CONFIG.expects("[]").returns("linux")
        Util.windows?.should == false
      end

      it "should correctly detect windows on windows platforms" do
        RbConfig::CONFIG.expects("[]").returns("win32")
        Util.windows?.should == true
      end
    end

    describe "#setup_windows_sleeper" do
      it "should set up a thread on the windows platform" do
        Thread.expects(:new)
        Util.expects("windows?").returns(true).once
        Util.setup_windows_sleeper
      end

      it "should not set up a thread on other platforms" do
        Thread.expects(:new).never
        Util.expects("windows?").returns(false).once
        Util.setup_windows_sleeper
      end
    end

    describe "#has_cf_class?" do
      before do
        logger = mock
        logger.stubs(:log)
        logger.stubs(:start)
        Log.configure(logger)

        config = mock
        config.stubs(:classesfile).returns("/some/file")
        Config.expects(:instance).returns(config)
      end

      it "should read the classes lines from the correct file" do
        File.expects(:readlines).with("/some/file")

        Util.has_cf_class?("test")
      end

      it "should support regular expression searches" do
        File.stubs(:readlines).returns(["test_class_test"])
        String.any_instance.expects(:match).with("^/").returns(true)
        String.any_instance.expects(:match).with(Regexp.new("class")).returns(true)

        Util.has_cf_class?("/class/").should == true
      end

      it "should support exact string matches" do
        File.stubs(:readlines).returns(["test_class_test"])
        String.any_instance.expects(:match).with("^/").returns(false)
        String.any_instance.expects(:match).with(Regexp.new("test_class_test")).never

        Util.has_cf_class?("test_class_test").should == true
      end

      it "should report a warning when the classes file cannot be parsed" do
        File.stubs(:readlines).returns(nil)
        Log.expects(:warn).with("Parsing classes file '/some/file' failed: NoMethodError: undefined method `each' for nil:NilClass")

        Util.has_cf_class?("test_class_test").should == false
      end
    end

    describe "#shellescape" do
      it "should return '' for empty strings" do
        Util.shellescape("").should == "''"
      end

      it "should quote newlines" do
        Util.shellescape("\n").should == "'\n'"
      end

      it "should escape unwanted characters" do
        Util.shellescape("foo;bar").should == 'foo\;bar'
        Util.shellescape('foo`bar').should == 'foo\`bar'
        Util.shellescape('foo$bar').should == 'foo\$bar'
        Util.shellescape('foo|bar').should == 'foo\|bar'
        Util.shellescape('foo&&bar').should == 'foo\&\&bar'
        Util.shellescape('foo||bar').should == 'foo\|\|bar'
        Util.shellescape('foo>bar').should == 'foo\>bar'
        Util.shellescape('foo<bar').should == 'foo\<bar'
        Util.shellescape('foobar').should == 'foobar'
      end
    end

    describe "#make_subscription" do
      it "should validate target types" do
        expect {
          Util.make_subscriptions("test", "test", "test")
        }.to raise_error("Unknown target type test")

        Config.any_instance.stubs(:collectives).returns(["test"])
        Util.make_subscriptions("test", :broadcast, "test")
      end

      it "should return a subscription for each collective" do
        Config.any_instance.stubs(:collectives).returns(["collective1", "collective2"])
        Util.make_subscriptions("test", :broadcast).should == [{:type=>:broadcast,
                                                                 :agent=>"test",
                                                                 :collective=>"collective1"},
                                                               {:type=>:broadcast,
                                                                 :agent=>"test",
                                                                 :collective=>"collective2"}]
      end

      it "should validate given collective" do
        Config.any_instance.stubs(:collectives).returns(["collective1", "collective2"])

        expect {
          Util.make_subscriptions("test", :broadcast, "test")
        }.to raise_error("Unknown collective 'test' known collectives are 'collective1, collective2'")
      end

      it "should return a single subscription array given a collective" do
        Config.any_instance.stubs(:collectives).returns(["collective1", "collective2"])
        Util.make_subscriptions("test", :broadcast, "collective1").should == [{:type=>:broadcast, :agent=>"test", :collective=>"collective1"}]
      end
    end

    describe "#subscribe" do
      it "should subscribe to multiple topics given an Array" do
        subs1 = {:agent => "test_agent", :type => "test_type", :collective => "test_collective"}
        subs2 = {:agent => "test_agent2", :type => "test_type2", :collective => "test_collective2"}

        MCollective::Connector::Stomp.any_instance.expects(:subscribe).with("test_agent", "test_type", "test_collective").once
        MCollective::Connector::Stomp.any_instance.expects(:subscribe).with("test_agent2", "test_type2", "test_collective2").once

        Util.subscribe([subs1, subs2])
      end

      it "should subscribe to a single topic given a hash" do
        MCollective::Connector::Stomp.any_instance.expects(:subscribe).with("test_agent", "test_type", "test_collective").once
        Util.subscribe({:agent => "test_agent", :type => "test_type", :collective => "test_collective"})
      end
    end

    describe "#unsubscribe" do
      it "should unsubscribe to multiple topics given an Array" do
        subs1 = {:agent => "test_agent", :type => "test_type", :collective => "test_collective"}
        subs2 = {:agent => "test_agent2", :type => "test_type2", :collective => "test_collective2"}
        MCollective::Connector::Stomp.any_instance.expects(:unsubscribe).with("test_agent", "test_type", "test_collective").once
        MCollective::Connector::Stomp.any_instance.expects(:unsubscribe).with("test_agent2", "test_type2", "test_collective2").once

        Util.unsubscribe([subs1, subs2])
      end

      it "should subscribe to a single topic given a hash" do
        MCollective::Connector::Stomp.any_instance.expects(:unsubscribe).with("test_agent", "test_type", "test_collective").once
        Util.unsubscribe({:agent => "test_agent", :type => "test_type", :collective => "test_collective"})
      end
    end

    describe "#empty_filter?" do
      it "should correctly compare empty filters" do
        Util.empty_filter?(Util.empty_filter).should == true
      end

      it "should treat an empty hash as an empty filter" do
        Util.empty_filter?({}).should == true
      end

      it "should detect non empty filters correctly" do
        filter = Util.empty_filter
        filter["cf_class"] << "meh"


        Util.empty_filter?(filter).should == false
      end
    end

    describe "#empty_filter" do
      it "should create correct empty filters" do
        Util.empty_filter.should == {"fact" => [], "cf_class" => [], "agent" => [], "identity" => [], "compound" => []}
      end
    end

    describe "#default_options" do
      it "should supply correct default options" do
        empty_filter = Util.empty_filter
        config_file = Util.config_file_for_user

        Util.default_options.should == {:verbose => false, :disctimeout => 2, :timeout => 5, :config => config_file, :filter => empty_filter, :collective => nil}
      end
    end

    describe "#has_fact?" do
      it "should handle missing facts correctly" do
        MCollective::Facts.expects("[]").with("foo").returns(nil).once
        Util.has_fact?("foo", "1", "==").should == false
      end

      it "should handle regex in a backward compatible way" do
        MCollective::Facts.expects("[]").with("foo").returns("foo").times(6)
        Util.has_fact?("foo", "foo", "=~").should == true
        Util.has_fact?("foo", "/foo/", "=~").should == true
        Util.has_fact?("foo", "foo", "=~").should == true
        Util.has_fact?("foo", "bar", "=~").should == false
        Util.has_fact?("foo", "/bar/", "=~").should == false
        Util.has_fact?("foo", "bar", "=~").should == false
      end

      it "should evaluate equality" do
        MCollective::Facts.expects("[]").with("foo").returns("foo").twice
        Util.has_fact?("foo", "foo", "==").should == true
        Util.has_fact?("foo", "bar", "==").should == false
      end

      it "should handle numeric comparisons correctly" do
        MCollective::Facts.expects("[]").with("foo").returns("1").times(8)
        Util.has_fact?("foo", "2", ">=").should == false
        Util.has_fact?("foo", "1", ">=").should == true
        Util.has_fact?("foo", "2", "<=").should == true
        Util.has_fact?("foo", "1", "<=").should == true
        Util.has_fact?("foo", "1", "<").should == false
        Util.has_fact?("foo", "1", ">").should == false
        Util.has_fact?("foo", "1", "!=").should == false
        Util.has_fact?("foo", "2", "!=").should == true
      end

      it "should handle alphabetic comparisons correctly" do
        MCollective::Facts.expects("[]").with("foo").returns("b").times(8)
        Util.has_fact?("foo", "c", ">=").should == false
        Util.has_fact?("foo", "a", ">=").should == true
        Util.has_fact?("foo", "a", "<=").should == false
        Util.has_fact?("foo", "b", "<=").should == true
        Util.has_fact?("foo", "b", "<").should == false
        Util.has_fact?("foo", "b", ">").should == false
        Util.has_fact?("foo", "b", "!=").should == false
        Util.has_fact?("foo", "a", "!=").should == true
      end
    end

    describe "#parse_fact_string" do
      it "should parse old style regex fact matches" do
        Util.parse_fact_string("foo=/bar/").should == {:fact => "foo", :value => "/bar/", :operator => "=~"}
        Util.parse_fact_string("foo = /bar/").should == {:fact => "foo", :value => "/bar/", :operator => "=~"}
      end

      it "should parse old style equality" do
        Util.parse_fact_string("foo=bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
        Util.parse_fact_string("foo = bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
      end

      it "should parse regex fact matches" do
        Util.parse_fact_string("foo=~bar").should == {:fact => "foo", :value => "bar", :operator => "=~"}
        Util.parse_fact_string("foo =~ bar").should == {:fact => "foo", :value => "bar", :operator => "=~"}
      end

      it "should treat => like >=" do
        Util.parse_fact_string("foo=>bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
        Util.parse_fact_string("foo => bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
      end

      it "should treat =< like <=" do
        Util.parse_fact_string("foo=<bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
        Util.parse_fact_string("foo =< bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
      end

      it "should parse less than or equal" do
        Util.parse_fact_string("foo<=bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
        Util.parse_fact_string("foo <= bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
      end

      it "should parse greater than or equal" do
        Util.parse_fact_string("foo>=bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
        Util.parse_fact_string("foo >= bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
      end

      it "should parse less than" do
        Util.parse_fact_string("foo<bar").should == {:fact => "foo", :value => "bar", :operator => "<"}
        Util.parse_fact_string("foo < bar").should == {:fact => "foo", :value => "bar", :operator => "<"}
      end

      it "should parse greater than" do
        Util.parse_fact_string("foo>bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
        Util.parse_fact_string("foo > bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
      end

      it "should parse greater than" do
        Util.parse_fact_string("foo>bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
        Util.parse_fact_string("foo > bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
      end

      it "should parse not equal" do
        Util.parse_fact_string("foo!=bar").should == {:fact => "foo", :value => "bar", :operator => "!="}
        Util.parse_fact_string("foo != bar").should == {:fact => "foo", :value => "bar", :operator => "!="}
      end

      it "should parse equal to" do
        Util.parse_fact_string("foo==bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
        Util.parse_fact_string("foo == bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
      end

      it "should fail for facts in the wrong format" do
        expect {
          Util.parse_fact_string("foo")
        }.to raise_error("Could not parse fact foo it does not appear to be in a valid format")
      end
    end

    describe "#eval_compound_statement" do
      it "should return correctly on a regex class statement" do
        Util.expects(:has_cf_class?).with("/foo/").returns(true)
        Util.eval_compound_statement({"statement" => "/foo/"}).should == true
        Util.expects(:has_cf_class?).with("/foo/").returns(false)
        Util.eval_compound_statement({"statement" => "/foo/"}).should == false
      end

      it "should return correcly for string and regex facts" do
        Util.expects(:has_fact?).with("foo", "bar", "==").returns(true)
        Util.eval_compound_statement({"statement" => "foo=bar"}).should == "true"
        Util.expects(:has_fact?).with("foo", "/bar/", "=~").returns(false)
        Util.eval_compound_statement({"statement" => "foo=/bar/"}).should == "false"
      end

      it "should return correctly on a string class statement" do
        Util.expects(:has_cf_class?).with("foo").returns(true)
        Util.eval_compound_statement({"statement" => "foo"}).should == true
        Util.expects(:has_cf_class?).with("foo").returns(false)
        Util.eval_compound_statement({"statement" => "foo"}).should == false
      end
    end
  end
end
