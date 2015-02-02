#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  class Aggregate
    module Result
      describe NumericResult do
        describe "#to_s" do
          it "should return empty string when no results were computed" do
            NumericResult.new({}, "test %d", :action).to_s.should == ""
          end

          it "should return the correctly formatted string" do
            num = NumericResult.new({:value => 1}, "test %d", :action).to_s
            num.should == "test 1"
          end
        end
      end
    end
  end
end
