#! /usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Matcher
    describe Parser do
      describe '#parse' do
        it "should parse statements seperated by '='" do
          parser = Parser.new("foo=bar")
          parser.execution_stack.should == [{"statement" => "foo=bar"}]
        end

        it "should parse statements seperated by '<'" do
          parser = Parser.new("foo<bar")
          parser.execution_stack.should == [{"statement" => "foo<bar"}]
        end

        it "should parse statements seperated by '>'" do
          parser = Parser.new("foo>bar")
          parser.execution_stack.should == [{"statement" => "foo>bar"}]
        end

        it "should parse statements seperated by '<='" do
          parser = Parser.new("foo<=bar")
          parser.execution_stack.should == [{"statement" => "foo<=bar"}]
        end

        it "should parse statements seperated by '>='" do
          parser = Parser.new("foo>=bar")
          parser.execution_stack.should == [{"statement" => "foo>=bar"}]
        end

        it "should parse class regex statements" do
          parser = Parser.new("/foo/")
          parser.execution_stack.should == [{"statement" => "/foo/"}]
        end

        it "should parse fact regex statements" do
          parser = Parser.new("foo=/bar/")
          parser.execution_stack.should == [{"statement" => "foo=/bar/"}]
        end

        it "should parse a correct 'and' token" do
          parser = Parser.new("foo=bar and bar=foo")
          parser.execution_stack.should == [{"statement" => "foo=bar"}, {"and" => "and"}, {"statement" => "bar=foo"}]
        end

        it "should not parse an incorrect and token" do
          expect {
            parser = Parser.new("and foo=bar")
          }.to raise_error(RuntimeError, /Parse errors found while parsing -S input.*/)
        end

        it "should parse a correct 'or' token" do
          parser = Parser.new("foo=bar or bar=foo")
          parser.execution_stack.should == [{"statement" => "foo=bar"}, {"or" => "or"}, {"statement" => "bar=foo"}]
        end

        it "should not parse an incorrect or token" do
          expect{
            parser = Parser.new("or foo=bar")
          }.to raise_error(RuntimeError, /Parse errors found while parsing -S input.*/)
        end

        it "should parse a correct 'not' token" do
          parser = Parser.new("! bar=foo")
          parser.execution_stack.should == [{"not" => "not"}, {"statement" => "bar=foo"}]
          parser = Parser.new("not bar=foo")
          parser.execution_stack.should == [{"not" => "not"}, {"statement" => "bar=foo"}]
        end

        it "should not parse an incorrect 'not' token" do
          expect{
            parser = Parser.new("foo=bar !")
          }.to raise_error(RuntimeError, /Parse errors found while parsing -S input.*/)
        end

        it "should parse correct parentheses" do
          parser = Parser.new("(foo=bar)")
          parser.execution_stack.should == [{"(" => "("}, {"statement" => "foo=bar"}, {")" => ")"}]
        end

        it "should fail on incorrect parentheses" do
          expect{
            parser = Parser.new(")foo=bar(")
          }.to raise_error(RuntimeError, /Malformed token\(s\) found while parsing -S input.*/)
        end

        it "should fail on missing parentheses" do
          expect{
            parser = Parser.new("(foo=bar")
          }.to raise_error(RuntimeError, /Missing parenthesis found while parsing -S input.*/)
        end

        it "should parse correctly formatted compound statements" do
          parser = Parser.new("(foo=bar or foo=rab) and (bar=foo)")
          parser.execution_stack.should == [{"(" => "("}, {"statement"=>"foo=bar"}, {"or"=>"or"}, {"statement"=>"foo=rab"},
                                            {")"=>")"}, {"and"=>"and"}, {"("=>"("}, {"statement"=>"bar=foo"},
                                            {")"=>")"}]
        end

      end
    end
  end
end
