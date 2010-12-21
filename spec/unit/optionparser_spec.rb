#!/usr/bin/env ruby

require 'mcollective'
require 'rubygems'
require 'rspec'

describe MCollective::Optionparser do
    before do
        @parser = MCollective::Optionparser.new
    end

    it "should parse old style regex fact matches" do
        @parser.send(:parse_fact, "foo=/bar/").should == {:fact => "foo", :value => "bar", :operator => "=~"}
        @parser.send(:parse_fact, "foo = /bar/").should == {:fact => "foo", :value => "bar", :operator => "=~"}
    end

    it "should parse old style equality" do
        @parser.send(:parse_fact, "foo=bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
        @parser.send(:parse_fact, "foo = bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
    end

    it "should parse regex fact matches" do
        @parser.send(:parse_fact, "foo=~bar").should == {:fact => "foo", :value => "bar", :operator => "=~"}
        @parser.send(:parse_fact, "foo =~ bar").should == {:fact => "foo", :value => "bar", :operator => "=~"}
    end

    it "should treat => like >=" do
        @parser.send(:parse_fact, "foo=>bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
        @parser.send(:parse_fact, "foo => bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
    end

    it "should treat =< like <=" do
        @parser.send(:parse_fact, "foo=<bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
        @parser.send(:parse_fact, "foo =< bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
    end

    it "should parse less than or equal" do
        @parser.send(:parse_fact, "foo<=bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
        @parser.send(:parse_fact, "foo <= bar").should == {:fact => "foo", :value => "bar", :operator => "<="}
    end

    it "should parse greater than or equal" do
        @parser.send(:parse_fact, "foo>=bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
        @parser.send(:parse_fact, "foo >= bar").should == {:fact => "foo", :value => "bar", :operator => ">="}
    end

    it "should parse less than" do
        @parser.send(:parse_fact, "foo<bar").should == {:fact => "foo", :value => "bar", :operator => "<"}
        @parser.send(:parse_fact, "foo < bar").should == {:fact => "foo", :value => "bar", :operator => "<"}
    end

    it "should parse greater than" do
        @parser.send(:parse_fact, "foo>bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
        @parser.send(:parse_fact, "foo > bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
    end

    it "should parse greater than" do
        @parser.send(:parse_fact, "foo>bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
        @parser.send(:parse_fact, "foo > bar").should == {:fact => "foo", :value => "bar", :operator => ">"}
    end

    it "should parse not equal" do
        @parser.send(:parse_fact, "foo!=bar").should == {:fact => "foo", :value => "bar", :operator => "!="}
        @parser.send(:parse_fact, "foo != bar").should == {:fact => "foo", :value => "bar", :operator => "!="}
    end

    it "should parse equal to" do
        @parser.send(:parse_fact, "foo==bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
        @parser.send(:parse_fact, "foo == bar").should == {:fact => "foo", :value => "bar", :operator => "=="}
    end
end
