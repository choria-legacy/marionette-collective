#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Util do
        before do
            class MCollective::Connector::Stomp<MCollective::Connector::Base; end
        end

        describe "#make_target" do
            it "should check for correct types" do
                expect {
                    Util.make_target("foo", "foo")
                }.to raise_error("Unknown target type foo")
            end

            it "should create topics for each collective" do
                c = MCollective::Config.instance
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
                c = MCollective::Config.instance
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
    end
end
