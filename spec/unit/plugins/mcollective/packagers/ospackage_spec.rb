#!/usr/bin/env rspec

require 'spec_helper'

MCollective::PluginManager.clear
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/pluginpackager/ospackage_packager.rb'

module MCollective
  module PluginPackager
    describe OspackagePackager do
      before :all do

        class OspackagePackager
          ENV = {"PATH" => "."}
        end

        class TestPlugin
          attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :iteration
          attr_accessor :postinstall

          def initialize
            @path = "/tmp"
            @packagedata = {:testpackage => {:files => ["/tmp/test.rb"],
                                             :dependencies => ["mcollective"],
                                             :description => "testpackage"}}
            @iteration = 1
            @postinstall = "/tmp/test.sh"
            @metadata = {:name => "testplugin",
                         :description => "A Test Plugin",
                         :author => "Psy",
                         :license => "Apache 2",
                         :version => "0",
                         :url => "http://foo.bar.com",
                         :timeout => 5}
            @vendor = "Puppet Labs"
            @target_path = "/tmp"
          end
        end

        @testplugin = TestPlugin.new
      end

      describe "#initialize" do
        it "should correctly identify a RedHat system" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("rpmbuild").returns(true)

          ospackage = OspackagePackager.new(@testplugin)
          ospackage.libdir.should == "usr/libexec/mcollective/mcollective/"
          ospackage.package_type.should == "RPM"
        end

        it "should correctly identify a Debian System" do
          File.expects(:exists?).with("/etc/redhat-release").returns(false)
          File.expects(:exists?).with("/etc/debian_version").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("ar").returns(true)

          ospackage = OspackagePackager.new(@testplugin)
          ospackage.libdir.should == "usr/share/mcollective/plugins/mcollective"
          ospackage.package_type.should == "Deb"
        end

        it "should raise an exception if it cannot identify the operating system" do
          File.expects(:exists?).with("/etc/redhat-release").returns(false)
          File.expects(:exists?).with("/etc/debian_version").returns(false)

          expect{
            ospackage = OspackagePackager.new(@testplugin)
          }.to raise_exception "error: cannot identify operating system."
        end

        it "should identify if rpmbuild is present for RedHat systems" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          File.expects(:exists?).with("./rpmbuild").returns(true)
          ospackage = OspackagePackager.new(@testplugin)
        end

        it "should raise an exception if rpmbuild is not present for RedHat systems" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          File.expects(:exists?).with("./rpmbuild").returns(false)
          expect{
            ospackage = OspackagePackager.new(@testplugin)
          }.to raise_error "error: package 'rpm-build' is not installed."
        end

        it "should identify if ar is present for Debian systems" do
          File.expects(:exists?).with("/etc/redhat-release").returns(false)
          File.expects(:exists?).with("/etc/debian_version").returns(true)
          File.expects(:exists?).with("./ar").returns(true)

          ospackage = OspackagePackager.new(@testplugin)
        end

        it "should raise an exception if the build tool is not present" do
          File.expects(:exists?).with("/etc/redhat-release").returns(false)
          File.expects(:exists?).with("/etc/debian_version").returns(true)
          File.expects(:exists?).with("./ar").returns(false)
          expect{
            ospackage = OspackagePackager.new(@testplugin)
          }.to raise_error "error: package 'ar' is not installed."
        end
      end

      describe "#create_packages" do
        it "should prepare temp directories, create a package and clean up when done" do
          OspackagePackager.any_instance.stubs(:gem).with("fpm", ">= 0.4.1")
          OspackagePackager.any_instance.stubs(:require).with("fpm")
          OspackagePackager.any_instance.stubs(:require).with("tmpdir")

          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("rpmbuild").returns(true)
          Dir.expects(:mktmpdir).with("mcollective_packager").returns("/tmp/mcollective_packager")
          FileUtils.expects(:mkdir_p).with("/tmp/mcollective_packager/usr/libexec/mcollective/mcollective/")

          ospackage = OspackagePackager.new(@testplugin)
          ospackage.expects(:prepare_tmpdirs).once
          ospackage.expects(:create_package).once
          ospackage.expects(:cleanup_tmpdirs).once

          ospackage.create_packages
        end
      end

      describe "#create_package" do
        before do
          module FPM
            module Package
              class Dir;end
              class RPM;end
            end
          end
        end

        it "should run fpm with the correct parameters" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("rpmbuild").returns(true)

          ospackage = OspackagePackager.new(@testplugin)
          ospackage.expects(:params)

          attributes = {:chdir => nil}
          fpm_dir = mock
          fpm_rpm = mock

          FPM::Package::Dir.expects(:new).returns(fpm_dir).once
          fpm_dir.expects(:attributes).returns(attributes)
          fpm_dir.expects(:input).with("usr/libexec/mcollective/mcollective/")
          FPM::Package.expects(:const_get).with("RPM").returns("FPM::Package::RPM")
          fpm_dir.expects(:convert).with("FPM::Package::RPM").returns(fpm_rpm)
          fpm_rpm.expects(:output).with("mcollective-testplugin-testpackage.rpm")

          fpm_rpm.expects(:cleanup)
          fpm_dir.expects(:cleanup)

          ospackage.create_package(:testpackage, @testplugin.packagedata[:testpackage])
        end
      end

      describe "#params" do
        it "should create all paramaters needed by fpm" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("rpmbuild").returns(true)
          ospackage = OspackagePackager.new(@testplugin)

          fpm_type = mock
          fpm_type.expects(:name=).with("mcollective-testplugin-testpackage")
          fpm_type.expects(:maintainer=).with("Psy")
          fpm_type.expects(:version=).with("0")
          fpm_type.expects(:url=).with("http://foo.bar.com")
          fpm_type.expects(:license=).with("Apache 2")
          fpm_type.expects(:iteration=).with(1)
          fpm_type.expects(:vendor=).with("Puppet Labs")
          fpm_type.expects(:description=).with("A Test Plugin\n\ntestpackage")
          fpm_type.expects(:dependencies=).with(["mcollective"])
          fpm_type.expects(:scripts).returns({"post-install" => nil})

          ospackage.params(fpm_type,:testpackage, @testplugin.packagedata[:testpackage])

        end
      end

      describe "#prepare_tmpdirs" do
        it "should create temp directories and copy package files" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("rpmbuild").returns(true)
          FileUtils.expects(:mkdir).with("/tmp/mcollective_packager/")
          FileUtils.expects(:cp_r).with("/tmp/test.rb", "/tmp/mcollective_packager/")

          ospackage = OspackagePackager.new(@testplugin)
          ospackage.workingdir = "/tmp/mcollective_packager/"
          ospackage.prepare_tmpdirs(@testplugin.packagedata[:testpackage])
        end
      end

      describe "#cleanup_tmpdirs" do
        it "should remove temp directories" do
          File.expects(:exists?).with("/etc/redhat-release").returns(true)
          OspackagePackager.any_instance.expects(:build_tool?).with("rpmbuild").returns(true)
          FileUtils.expects(:rm_r).with("/tmp/mcollective_packager/")

          ospackage = OspackagePackager.new(@testplugin)
          ospackage.tmpdir = "/tmp/mcollective_packager/"
          ospackage.cleanup_tmpdirs
        end
      end
    end
  end
end
