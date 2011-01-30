#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Util do
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

                Util.default_options.should == {:verbose => false, :disctimeout => 2, :timeout => 5, :config => config_file, :filter => empty_filter}
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
