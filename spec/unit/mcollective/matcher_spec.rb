#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Matcher do
    describe "#create_function_hash" do
      it "should create a correct hash for a 'normal' function call using single quotes" do
        result = Matcher.create_function_hash("foo('bar').res=1")
        result["value"].should == "res"
        result["params"].should == "bar"
        result["r_compare"].should == "1"
        result["operator"].should == "=="
        result["name"].should == "foo"
      end

      it "should create a correct hash for a 'normal' function call using double quotes" do
        result = Matcher.create_function_hash('foo("bar").res=1')
        result["value"].should == "res"
        result["params"].should == "bar"
        result["r_compare"].should == "1"
        result["operator"].should == "=="
        result["name"].should == "foo"
       end

      it "should create a correct hash when a paramater contains a dot value" do
        result = Matcher.create_function_hash("foo('bar.1').res=1")
        result["value"].should == "res"
        result["params"].should == "bar.1"
        result["r_compare"].should == "1"
        result["operator"].should == "=="
        result["name"].should == "foo"
      end

      it "should create a correct hash when right compare value is a regex" do
        result = Matcher.create_function_hash("foo('bar').res=/reg/")
        result["value"].should == "res"
        result["params"].should == "bar"
        result["r_compare"].should == /reg/
        result["operator"].should == "=~"
        result["name"].should == "foo"
      end

      it "should create a correct hash when the operator is >= or <=" do
        result = Matcher.create_function_hash("foo('bar').res<=1")
        result["value"].should == "res"
        result["params"].should == "bar"
        result["r_compare"].should == "1"
        result["operator"].should == "<="
        result["name"].should == "foo"

        result = Matcher.create_function_hash("foo('bar').res>=1")
        result["value"].should == "res"
        result["params"].should == "bar"
        result["r_compare"].should == "1"
        result["operator"].should == ">="
        result["name"].should == "foo"
      end

      it "should create a correct hash when no dot value is present" do
        result = Matcher.create_function_hash("foo('bar')<=1")
        result["value"].should == nil
        result["params"].should == "bar"
        result["r_compare"].should == "1"
        result["operator"].should == "<="
        result["name"].should == "foo"
      end

      it "should create a correct hash when a dot is present in a parameter but no dot value is present" do
        result = Matcher.create_function_hash("foo('bar.one')<=1")
        result["value"].should == nil
        result["params"].should == "bar.one"
        result["r_compare"].should == "1"
        result["operator"].should == "<="
        result["name"].should == "foo"
      end

      it "should create a correct hash when multiple dots are present in parameters but no dot value is present" do
        result = Matcher.create_function_hash("foo('bar.one.two, bar.three.four')<=1")
        result["value"].should == nil
        result["params"].should == "bar.one.two, bar.three.four"
        result["r_compare"].should == "1"
        result["operator"].should == "<="
        result["name"].should == "foo"
      end

      it "should create a correct hash when no parameters are given" do
        result = Matcher.create_function_hash("foo()<=1")
        result["value"].should == nil
        result["params"].should == nil
        result["r_compare"].should == "1"
        result["operator"].should == "<="
        result["name"].should == "foo"
     end

      it "should create a correct hash parameters are empty strings" do
        result = Matcher.create_function_hash("foo('')=1")
        result["value"].should == nil
        result["params"].should == ""
        result["r_compare"].should == "1"
        result["operator"].should == "=="
        result["name"].should == "foo"
      end
    end

    describe "#execute_function" do
      it "should return the result of an evaluated function with a dot value" do
        data = mock
        data.expects(:send).with("value").returns("success")
        MCollective::Data.expects(:send).with("foo", "bar").returns(data)
        result = Matcher.execute_function({"name" => "foo", "params" => "bar", "value" => "value"})
        result.should == "success"
      end

      it "should return the result of an evaluated function without a dot value" do
        MCollective::Data.expects(:send).with("foo", "bar").returns("success")
        result = Matcher.execute_function({"name" => "foo", "params" => "bar"})
        result.should == "success"
      end

      it "should return nil if the result cannot be evaluated" do
        data = mock
        data.expects(:send).with("value").raises("error")
        Data.expects(:send).with("foo", "bar").returns(data)
        result = Matcher.execute_function({"name" => "foo", "params" => "bar", "value" => "value"})
        result.should == nil
      end
    end

    describe "#eval_compound_statement" do
      it "should return correctly on a regex class statement" do
        Util.expects(:has_cf_class?).with("/foo/").returns(true)
        Matcher.eval_compound_statement({"statement" => "/foo/"}).should == true
        Util.expects(:has_cf_class?).with("/foo/").returns(false)
        Matcher.eval_compound_statement({"statement" => "/foo/"}).should == false
      end

      it "should return correcly for string and regex facts" do
        Util.expects(:has_fact?).with("foo", "bar", "==").returns(true)
        Matcher.eval_compound_statement({"statement" => "foo=bar"}).should == "true"
        Util.expects(:has_fact?).with("foo", "/bar/", "=~").returns(false)
        Matcher.eval_compound_statement({"statement" => "foo=/bar/"}).should == "false"
      end

      it "should return correctly on a string class statement" do
        Util.expects(:has_cf_class?).with("foo").returns(true)
        Matcher.eval_compound_statement({"statement" => "foo"}).should == true
        Util.expects(:has_cf_class?).with("foo").returns(false)
        Matcher.eval_compound_statement({"statement" => "foo"}).should == false
      end
    end

    describe "#eval_compound_fstatement" do
      describe "it should return false if a string, true or false are compared with > or <" do
        let(:function_hash) do
          {"name" => "foo",
           "params" => "bar",
           "value" => "value",
           "operator" => "<",
           "r_compare" => "teststring"}
        end


        it "should return false if a string is compare with a < or >" do
          Matcher.expects(:execute_function).returns("teststring")
          result = Matcher.eval_compound_fstatement(function_hash)
          result.should == false
        end

        it "should return false if a TrueClass is compared with a < or > " do
          Matcher.expects(:execute_function).returns(true)
          result = Matcher.eval_compound_fstatement(function_hash)
          result.should == false
        end

        it "should return false if a FalseClass is compared with a < or >" do
          Matcher.expects(:execute_function).returns(false)
          result = Matcher.eval_compound_fstatement(function_hash)
          result.should == false
        end

        it "should return false immediately if the function execution returns nil" do
          Matcher.expects(:execute_function).returns(nil)
          result = Matcher.eval_compound_fstatement(function_hash)
          result.should == false
        end
      end

      describe "it should return false if backticks are present in parameters and if non strings are compared with regex's" do
        before :each do
          @function_hash = {"name" => "foo",
                           "params" => "bar",
                           "value" => "value",
                           "operator" => "=",
                           "r_compare" => "1"}
        end

        it "should return false if a backtick is present in a parameter" do
          @function_hash["params"] = "`bar`"
          Matcher.expects(:execute_function).returns("teststring")
          MCollective::Log.expects(:debug).with("Cannot use backticks in function parameters")
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == false
        end

        it "should return false if left compare object isn't a string and right compare is a regex" do
          Matcher.expects(:execute_function).returns(1)
          @function_hash["r_compare"] = "/foo/"
          @function_hash["operator"] = "=~"
          MCollective::Log.expects(:debug).with("Cannot do a regex check on a non string value.")
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == false
        end
      end

      describe "it should return the expected result for valid function hashes" do
        before :each do
          @function_hash = {"name" => "foo",
                            "params" => "bar",
                            "value" => "value",
                            "operator" => "=",
                            "r_compare" => ""}
        end

        it "should return true if right value is a regex and matches the left value" do
          Matcher.expects(:execute_function).returns("teststring")
          @function_hash["r_compare"] = /teststring/
          @function_hash["operator"] = "=~"
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == true
        end

        it "should return false if right value is a regex and matches the left value and !=~ is the operator" do
          Matcher.expects(:execute_function).returns("teststring")
          @function_hash["r_compare"] = /teststring/
          @function_hash["operator"] = "!=~"
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == false
        end

        it "should return false if right value is a regex, operator is != and regex equals left value" do
          Matcher.expects(:execute_function).returns("teststring")
          @function_hash["r_compare"] = /teststring/
          @function_hash["operator"] = "!=~"
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == false
        end

        it "should return false if right value is a regex and does not match left value" do
          Matcher.expects(:execute_function).returns("testsnotstring")
          @function_hash["r_compare"] = /teststring/
          @function_hash["operator"] = "=~"
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == false
        end

        it "should return true if left value logically compares to the right value" do
          Matcher.expects(:execute_function).returns(1)
          @function_hash["r_compare"] = 1
          @function_hash["operator"] = ">="
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == true
       end

       it "should return true if we do a false=false comparison" do
          Matcher.expects(:execute_function).returns(false)
          @function_hash["r_compare"] = false
          @function_hash["operator"] = "=="
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == true
       end

        it "should return false if left value does not logically compare to right value" do
          Matcher.expects(:execute_function).returns("1")
          @function_hash["r_compare"] = "1"
          @function_hash["operator"] = ">"
          result = Matcher.eval_compound_fstatement(@function_hash)
          result.should == false
        end
      end
    end

    describe "#create_compound_callstack" do
      it "should create a callstack from a valid call_string" do
        result = Matcher.create_compound_callstack("foo('bar')=1 and bar=/bar/")
        result.should == [{"fstatement" => {"params"=>"bar", "name"=>"foo", "operator"=>"==", "r_compare"=>"1"}}, {"and" => "and"}, {"statement" => "bar=/bar/"}]
      end
    end
  end
end
