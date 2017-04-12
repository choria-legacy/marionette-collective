#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Result do
      before(:each) do
        @result = Result.new("tester", "test", {:foo => "bar", :bar => "baz"})
      end

      it "should include Enumerable" do
        Result.ancestors.include?(Enumerable).should == true
      end

      describe "#initialize" do
        it "should set the agent" do
          @result.agent.should == "tester"
        end

        it "should set the action" do
          @result.action.should == "test"
        end

        it "should set the results" do
          @result.results.should == {:foo => "bar", :bar => "baz"}
        end
      end

      describe "#convert_data_based_on_ddl" do
        it "should convert string data to symbol data based on the DDL" do
          ddl = DDL.new("rspec", :agent, false)
          ddl.metadata(:name => "name", :description => "description", :author => "author", :license => "license", :version => "version", :url => "url", :timeout => "timeout")
          ddl.action("test", :description => "rspec")
          ddl.instance_variable_set("@current_entity", "test")
          ddl.output(:one, :description => "rspec one", :display_as => "One")

          DDL.expects(:new).with("rspec").returns(ddl)

          raw_result = {
            "sender" => "rspec.id",
            "statuscode" => 1,
            "statusmsg" => "rspec status",
            "data" => {
              "one" => 1,
              "two" => 2
            }
          }

          result = Result.new("rspec", "test", raw_result)
          expect(result.data).to eq(
            :one => 1,
            "two" => 2
          )
        end
      end

      describe "#[]" do
        it "should access the results hash and return correct data" do
          @result[:foo].should == "bar"
          @result[:bar].should == "baz"
        end
      end

      describe "#[]=" do
        it "should set the correct result data" do
          @result[:meh] = "blah"

          @result[:foo].should == "bar"
          @result[:bar].should == "baz"
          @result[:meh].should == "blah"
        end
      end

      describe "#fetch" do
        it "should fetch data with the correct default behavior" do
          @result.fetch(:foo, "default").should == "bar"
          @result.fetch(:rspec, "default").should == "default"
        end
      end

      describe "#each" do
        it "should itterate all the pairs" do
          data = {}

          @result.each {|k,v| data[k] = v}

          data[:foo].should == "bar"
          data[:bar].should == "baz"
        end
      end

      describe "#to_json" do
        it "should correctly json encode teh data" do
          result = Result.new("tester", "test", {:statuscode => 0, :statusmsg => "OK", :sender => "rspec",  :data => {:foo => "bar", :bar => "baz"}})
          JSON.load(result.to_json).should == {"agent" => "tester", "action" => "test", "statuscode" => 0, "statusmsg" => "OK", "sender" => "rspec", "data" => {"foo" => "bar", "bar" => "baz"}}
        end
      end

      describe "#<=>" do
        it "should implement the Combined Comparison operator based on sender name" do
          result_a = Result.new("tester",
                                "test",
                                { :statuscode => 0,
                                  :statusmsg => "OK",
                                  :sender => "a_rspec",
                                  :data => {}})
          result_b = Result.new("tester",
                                "test",
                                { :statuscode => 0,
                                  :statusmsg => "OK",
                                  :sender => "b_rspec",
                                  :data => {}})

          (result_a <=> result_b).should == -1
          (result_b <=> result_a).should == 1
          (result_a <=> result_a).should == 0
        end
      end
    end
  end
end
