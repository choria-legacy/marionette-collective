#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

describe MCollective::Util do
    it "should correctly compare empty filters" do
        MCollective::Util.empty_filter?(MCollective::Util.empty_filter).should == true
    end

    it "should treat an empty hash as an empty filter" do
        MCollective::Util.empty_filter?({}).should == true
    end

    it "should detect non empty filters correctly" do
        filter = MCollective::Util.empty_filter
        filter["cf_class"] << "meh"


        MCollective::Util.empty_filter?(filter).should == false
    end

    it "should create correct empty filters" do
        MCollective::Util.empty_filter.should == {"fact" => [], "cf_class" => [], "agent" => [], "identity" => []}
    end

    it "should supply correct default options" do
        empty_filter = MCollective::Util.empty_filter
        config_file = MCollective::Util.config_file_for_user

        MCollective::Util.default_options.should == {:verbose => false, :disctimeout => 2, :timeout => 5, :config => config_file, :filter => empty_filter}
    end

    it "should parse old style regex fact matches" do
        MCollective::Util.parse_fact_string("foo=/bar/").should == {:fact => "foo", :value => "bar", :operator => "=~"}
        MCollective::Util.parse_fact_string("foo = /bar/").should == {:fact => "foo", :value => "bar", :operator => "=~"}
    end

    it "should parse old style equality" do
        MCollective::Util.parse_fact_string("foo=bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
        MCollective::Util.parse_fact_string("foo = bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
    end

    it "should parse regex fact matches" do
        MCollective::Util.parse_fact_string("foo=~bar").should == {:fact => "foo", :value => "bar", :operator => "=~"}
        MCollective::Util.parse_fact_string("foo =~ bar").should == {:fact => "foo", :value => "bar", :operator => "=~"}
    end

    it "should treat => like >=" do
        MCollective::Util.parse_fact_string("foo=>bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
        MCollective::Util.parse_fact_string("foo => bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
    end

    it "should treat =< like <=" do
        MCollective::Util.parse_fact_string("foo=<bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
        MCollective::Util.parse_fact_string("foo =< bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
    end

    it "should parse less than or equal" do
        MCollective::Util.parse_fact_string("foo<=bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
        MCollective::Util.parse_fact_string("foo <= bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
    end

    it "should parse greater than or equal" do
        MCollective::Util.parse_fact_string("foo>=bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
        MCollective::Util.parse_fact_string("foo >= bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
    end

    it "should parse less than" do
        MCollective::Util.parse_fact_string("foo<bar").should == {:fact => "foo", :value => "bar", :operator => "<"}
        MCollective::Util.parse_fact_string("foo < bar").should == {:fact => "foo", :value => "bar", :operator => "<"}
    end

    it "should parse greater than" do
        MCollective::Util.parse_fact_string("foo>bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
        MCollective::Util.parse_fact_string("foo > bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
    end

    it "should parse greater than" do
        MCollective::Util.parse_fact_string("foo>bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
        MCollective::Util.parse_fact_string("foo > bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
    end

    it "should parse not equal" do
        MCollective::Util.parse_fact_string("foo!=bar").should == {:fact => "foo", :value => "bar", :operator => "!="}
        MCollective::Util.parse_fact_string("foo != bar").should == {:fact => "foo", :value => "bar", :operator => "!="}
    end

    it "should parse equal to" do
        MCollective::Util.parse_fact_string("foo==bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
        MCollective::Util.parse_fact_string("foo == bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
    end
end
