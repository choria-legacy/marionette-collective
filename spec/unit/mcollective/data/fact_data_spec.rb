#!/usr/bin/env rspec

require 'spec_helper'

require 'mcollective/data/fact_data'

module MCollective
  module Data
    describe Fact_data do
      describe "#query_data" do
        before :each do
          @ddl = mock('DDL')
          @ddl.stubs(:dataquery_interface).returns({:output => {}})
          @ddl.stubs(:meta).returns({:timeout => 1})
          DDL.stubs(:new).returns(@ddl)
          @plugin = Fact_data.new

          facts_plugin = mock('fact_plugin')
          PluginManager.stubs(:[]).with('facts_plugin').returns(facts_plugin)

          facts_plugin.expects(:get_facts).returns({
            "foo" => "foo-value",
            "one" => {
              "one" => "one-one",
              "two" => {
                "one" => "one-two-one",
                "two" => "one-two-two",
              },
            },
            "some_array" => [
              "a",
              "b",
            ],
          })
        end

        it 'should return an unfound fact as false' do
          @plugin.query_data("bar")

          @plugin.result[:exists].should == false
          @plugin.result[:value].should == false
          @plugin.result[:value_encoding].should == false
        end

        it "should be able to find a value at top level" do
          @plugin.query_data("foo")

          @plugin.result[:exists].should == true
          @plugin.result[:value].should == "foo-value"
          @plugin.result[:value_encoding].should == 'text/plain'
        end

        it 'should be able to walk down to a hash element' do
          @plugin.query_data("one.one")

          @plugin.result[:exists].should == true
          @plugin.result[:value].should == "one-one"
          @plugin.result[:value_encoding].should == 'text/plain'
        end

        it 'should be able to walk down to a hash' do
          @plugin.query_data("one.two")

          @plugin.result[:exists].should == true

          @plugin.result[:value].should == {
            "one" => "one-two-one",
            "two" => "one-two-two",
          }.to_json
          @plugin.result[:value_encoding].should == 'application/json'

        end

        it 'should be able to walk down to an array' do
          @plugin.query_data("some_array")

          @plugin.result[:exists].should == true
          @plugin.result[:value].should == [ "a", "b" ].to_json
          @plugin.result[:value_encoding].should == 'application/json'
        end

        it 'should be able to walk down to an array element' do
          @plugin.query_data("some_array.0")

          @plugin.result[:exists].should == true
          @plugin.result[:value].should == "a"
          @plugin.result[:value_encoding].should == 'text/plain'
        end
      end
    end
  end
end
