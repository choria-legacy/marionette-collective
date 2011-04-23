#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Util do
        before do
            class MCollective::Connector::Stomp<MCollective::Connector::Base; end

            PluginManager.clear
            PluginManager << {:type => "connector_plugin", :class => MCollective::Connector::Stomp.new}
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

        describe "#make_target" do
            it "should check for correct types" do
                expect {
                    Util.make_target("foo", "foo")
                }.to raise_error("Unknown target type foo")
            end

            it "should create topics for each collective" do
                c = Config.instance
                c.instance_variable_set("@collectives", ["one", "two"])
                c.instance_variable_set("@topicprefix", "/topic/")
                c.instance_variable_set("@topicsep", ".")

                Util.make_target("foo", :command).should == ["/topic/one.foo.command", "/topic/two.foo.command"]
            end

            it "should validate the requested collective exist" do
                c = MCollective::Config.instance
                c.instance_variable_set("@collectives", ["one", "two"])

                expect {
                    Util.make_target("foo", :command, "meh")
                }.to raise_error("Unknown collective 'meh' known collectives are 'one, two'")
            end

            it "should support creating a topic for a specific collective" do
                c = Config.instance
                c.instance_variable_set("@collectives", ["one", "two"])
                c.instance_variable_set("@topicprefix", "/topic/")
                c.instance_variable_set("@topicsep", ".")

                Util.make_target("foo", :command, "one").should == "/topic/one.foo.command"
            end
        end

        describe "#subscribe" do
            it "should subscribe to multiple topics given an Array" do
                MCollective::Connector::Stomp.any_instance.expects(:subscribe).with("foo").once
                MCollective::Connector::Stomp.any_instance.expects(:subscribe).with("bar").once

                Util.subscribe(["foo", "bar"])
            end

            it "should subscribe to a single topic given a string" do
                MCollective::Connector::Stomp.any_instance.expects(:subscribe).with("foo").once

                Util.subscribe("foo")
            end
        end

        describe "#unsubscribe" do
            it "should unsubscribe to multiple topics given an Array" do
                MCollective::Connector::Stomp.any_instance.expects(:unsubscribe).with("foo").once
                MCollective::Connector::Stomp.any_instance.expects(:unsubscribe).with("bar").once

                Util.unsubscribe(["foo", "bar"])
            end

            it "should subscribe to a single topic given a string" do
                MCollective::Connector::Stomp.any_instance.expects(:unsubscribe).with("foo").once

                Util.unsubscribe("foo")
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
                Util.empty_filter.should == {"fact" => [], "cf_class" => [], "agent" => [], "identity" => []}
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
        end

        describe "#parse_msgtarget" do
            it "should correctly parse supplied targets based on config" do
                Config.any_instance.stubs("topicsep").returns(".")
                Config.any_instance.stubs("topicprefix").returns("/topic/")

                Util.parse_msgtarget("/topic/mcollective.discovery.command").should == {:collective => "mcollective", :agent => "discovery"}
            end

            it "should raise an error on failure" do
                Config.any_instance.stubs("topicsep").returns(".")
                Config.any_instance.stubs("topicprefix").returns("/topic/")

                expect { Util.parse_msgtarget("foo") }.to raise_error(/could not figure out agent and collective from foo/)
            end
        end
    end
end
