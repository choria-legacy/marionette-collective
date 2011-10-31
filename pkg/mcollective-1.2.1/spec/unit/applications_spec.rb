#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Applications do
        describe "#filter_extra_options" do
            it "should parse --config=x" do
                ["--config=x --foo=bar -f -f bar", "--foo=bar --config=x -f -f bar"].each do |t|
                    Applications.filter_extra_options(t).should == "--config=x"
                end
            end

            it "should parse --config x" do
                ["--config x --foo=bar -f -f bar", "--foo=bar --config x -f -f bar"].each do |t|
                    Applications.filter_extra_options(t).should == "--config=x"
                end
            end

            it "should parse -c x" do
                ["-c x --foo=bar -f -f bar", "--foo=bar -c x -f -f bar"].each do |t|
                    Applications.filter_extra_options(t).should == "--config=x"
                end
            end
        end
    end
end
