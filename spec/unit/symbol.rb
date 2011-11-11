#!/usr/bin/env ruby

require 'spec_helper'

class Symbol
  describe "#<=>" do
    it "should be sortable" do
      [:foo, :bar].sort.should == [:bar, :foo]
    end
  end
end
