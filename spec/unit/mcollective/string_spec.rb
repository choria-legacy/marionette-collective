#!/usr/bin/env rspec

require 'spec_helper'

class String
  describe "#start_with?" do
    it "should return true for matches" do
      "hello world".start_with?("hello").should == true
    end

    it "should return false for non matches" do
      "hello world".start_with?("world").should == false
    end
  end
end
