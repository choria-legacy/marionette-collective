#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  class Aggregate
    module Result
      describe CollectionResult do
        describe "#to_s" do
         it "should return the correctly formatted string" do
           result = CollectionResult.new({:output => [:test], :value => {"foo" => 3, "bar" => 2}}, "%s:%s", :action).to_s
           result.should == "    foo:3\n    bar:2"
         end
        end
      end
    end
  end
end
