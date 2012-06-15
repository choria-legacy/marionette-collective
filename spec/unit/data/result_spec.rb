#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Data
    describe Result do
      before(:each) do
        @result = Result.new
      end

      describe "#[]=" do
        it "should only allow trusted types of data to be saved" do
          expect { @result["rspec"] = Time.now }.to raise_error
          @result["rspec"] = 1
          @result["rspec"] = 1.1
          @result["rspec"] = "rspec"
          @result["rspec"] = true
          @result["rspec"] = false
        end

        it "should set the correct value" do
          @result["rspec"] = "rspec value"
          @result.instance_variable_get("@data").should == {:rspec => "rspec value"}
        end
      end

      describe "#include" do
        it "should return the correct list of keys" do
          @result["x"] = "1"
          @result[:y] = "2"
          @result.keys.sort.should == [:x, :y]
        end
      end

      describe "#include?" do
        it "should correctly report that a key is present or absent" do
          @result.include?("rspec").should == false
          @result.include?(:rspec).should == false
          @result["rspec"] = "rspec"
          @result.include?("rspec").should == true
          @result.include?(:rspec).should == true
        end
      end

      describe "#[]" do
        it "should retrieve the correct information" do
          @result["rspec"].should == nil
          @result[:rspec].should == nil
          @result["rspec"] = "rspec value"
          @result["rspec"].should == "rspec value"
          @result[:rspec].should == "rspec value"
        end
      end

      describe "#method_missing" do
        it "should retrieve the correct data" do
          @result["rspec"] = "rspec value"
          @result.rspec.should == "rspec value"
        end
      end
    end
  end
end
