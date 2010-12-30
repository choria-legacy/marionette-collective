#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Optionparser do
        before do
            @parser = Optionparser.new
        end

        describe "#parse" do
            it "should parse MCOLLECTIVE_EXTRA_OPTS" do
                ENV["MCOLLECTIVE_EXTRA_OPTS"] = "--dt 999"
                @parser.parse[:disctimeout].should == 999
            end
        end
    end
end
