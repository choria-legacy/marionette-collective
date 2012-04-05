#!/usr/bin/env rspec

require 'spec_helper'

MCollective::PluginManager.clear
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/pluginpackager/ospackage_packager.rb'

module MCollective
  module PluginPackager
    describe "#initialize" do

      before :all do
        @packager = mock()
        @packager.stubs(:new)
      end

      it "should correctly set members and create the correct packager on redhat" do
        File.expects(:exists?).with("/etc/redhat-release").returns(true)
        PluginPackager.expects(:[]).with("RpmpackagePackager").returns(@packager)
        ospackager = OspackagePackager.new("package")
        ospackager.package_type.should == "RPM"
      end

      it "should correctly set members and create the correct packager on debian" do
        File.expects(:exists?).with("/etc/redhat-release").returns(false)
        File.expects(:exists?).with("/etc/debian_version").returns(true)
        PluginPackager.expects(:[]).with("DebpackagePackager").returns(@packager)
        ospackager = OspackagePackager.new("package")
        ospackager.package_type.should == "Deb"
      end

      it "should raise an exception if the os can't be identified" do
        File.expects(:exists?).with("/etc/redhat-release").returns(false)
        File.expects(:exists?).with("/etc/debian_version").returns(false)
        expect{
          OspackagePackager.new("package")
        }.to raise_error RuntimeError
      end
    end

    describe "#create_packages" do
      before :all do
        @packager = mock
        @packager.stubs(:new).returns(@packager)
      end

      it "should call a packagers create_packages class" do
        File.expects(:exists?).with("/etc/redhat-release").returns(true)
        PluginPackager.expects(:[]).with("RpmpackagePackager").returns(@packager)
       @packager.expects(:create_packages)
        ospackager = OspackagePackager.new("package")
        ospackager.class.should == OspackagePackager
        ospackager.create_packages
      end
    end
  end
end
