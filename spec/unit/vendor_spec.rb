#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Vendor do
    describe "#vendor_dir" do
      it "should return correct vendor directory" do
        specdir = File.dirname(__FILE__)
        expected_dir = File.expand_path("#{specdir}/../../lib/mcollective/vendor")
        Vendor.vendor_dir.should == expected_dir
      end
    end

    describe "#load_entry" do
      it "should attempt to load the correct path" do
        specdir = File.dirname(__FILE__)
        expected_dir = File.expand_path("#{specdir}/../../lib/mcollective/vendor")

        Class.any_instance.stubs("load").with("#{expected_dir}/foo").once

        Vendor.load_entry("foo")
      end
    end

    describe "#require_libs" do
      it "should require the vendor loader" do
        Class.any_instance.stubs("require").with("mcollective/vendor/require_vendored").once

        Vendor.require_libs
      end
    end
  end
end
