#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

describe MCollective::Optionparser do
    before do
        @parser = MCollective::Optionparser.new
    end

    it "should parse MCOLLECTIVE_EXTRA_OPTS" do
        ENV["MCOLLECTIVE_EXTRA_OPTS"] = "--dt 999"
        @parser.parse[:disctimeout].should == 999
    end
end
