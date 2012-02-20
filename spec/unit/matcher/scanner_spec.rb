#! /usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Matcher
    describe 'scanner' do
      it "should identify a '(' token" do
        scanner = Scanner.new("(")
        token = scanner.get_token
        token.should == ["(", "("]
      end

      it "should identify a ')' token" do
        scanner = Scanner.new(")")
        token = scanner.get_token
        token.should == [")", ")"]
      end

      it "should identify a 'and' token" do
        scanner = Scanner.new("and ")
        token = scanner.get_token
        token.should == ["and", "and"]
      end

      it "should identify a 'or' token" do
        scanner = Scanner.new("or ")
        token = scanner.get_token
        token.should == ["or", "or"]
      end

      it "should identify a 'not' token" do
        scanner = Scanner.new("not ")
        token = scanner.get_token
        token.should == ["not", "not"]
      end

      it "should identify a '!' token" do
        scanner = Scanner.new("!")
        token = scanner.get_token
        token.should == ["not", "not"]
      end

      it "should identify a fact statement token" do
        scanner = Scanner.new("foo=bar")
        token = scanner.get_token
        token.should == ["statement", "foo=bar"]
      end

      it "should identify a fact statement token" do
        scanner = Scanner.new("foo=bar")
        token = scanner.get_token
        token.should == ["statement", "foo=bar"]
      end

      it "should identify a class statement token" do
        scanner = Scanner.new("/class/")
        token = scanner.get_token
        token.should == ["statement", "/class/"]
      end

      it "should fail if expression terminates with 'and'" do
        scanner = Scanner.new("and")

        expect {
          token = scanner.get_token
        }.to raise_error("Class name cannot be 'and', 'or', 'not'. Found 'and'")
      end
    end
  end
end
