#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe DDL do
    before do
      Cache.delete!(:ddl) rescue nil
    end

    describe "#new" do
      it "should default to agent ddls" do
        DDL::AgentDDL.expects(:new).once
        DDL.new("rspec")
      end

      it "should return the correct plugin ddl class" do
        DDL.new("rspec", :agent, false).class.should == DDL::AgentDDL
      end

      it "should default to base when no specific class exist" do
        DDL.new("rspec", :rspec, false).class.should == DDL::Base
      end
    end

    describe "#load_and_cache" do
      it "should setup the cache" do
        Cache.setup(:ddl)

        Cache.expects(:setup).once.returns(true)
        DDL.load_and_cache("rspec", :agent, false)
      end

      it "should attempt to read from the cache and return found ddl" do
        Cache.expects(:setup)
        Cache.expects(:read).with(:ddl, "agent/rspec").returns("rspec")
        DDL.load_and_cache("rspec", :agent, false).should == "rspec"
      end

      it "should handle cache misses then create and save a new ddl object" do
        Cache.expects(:setup)
        Cache.expects(:read).with(:ddl, "agent/rspec").raises("failed")
        Cache.expects(:write).with(:ddl, "agent/rspec", kind_of(DDL::AgentDDL)).returns("rspec")

        DDL.load_and_cache("rspec", :agent, false).should == "rspec"
      end
    end

    describe "#string_to_number" do
      it "should turn valid strings into numbers" do
        ["1", "0", "9999"].each do |i|
          DDL.string_to_number(i).class.should == Fixnum
        end

        ["1.1", "0.0", "9999.99"].each do |i|
          DDL.string_to_number(i).class.should == Float
        end
      end

      it "should raise errors for invalid values" do
        expect { DDL.string_to_number("rspec") }.to raise_error
      end
    end

    describe "#string_to_boolean" do
      it "should turn valid strings into boolean" do
        ["true", "yes", "1"].each do |t|
          DDL.string_to_boolean(t).should == true
          DDL.string_to_boolean(t.upcase).should == true
        end

        ["false", "no", "0"].each do |f|
          DDL.string_to_boolean(f).should == false
          DDL.string_to_boolean(f.upcase).should == false
        end
      end

      it "should raise errors for invalid values" do
        expect { DDL.string_to_boolean("rspec") }.to raise_error
      end
    end

  end
end
