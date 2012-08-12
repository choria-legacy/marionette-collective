#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/pluginpackager/rpmpackage_packager.rb'

module MCollective
  module PluginPackager
    describe RpmpackagePackager do
      let(:maketmpdir) do
        tmpdir = Dir.mktmpdir("mc-test")
        @tmpdirs << tmpdir
        tmpdir
      end

      before :all do
        @tmpdirs = []
      end

      before :each do
        PluginPackager.stubs(:build_tool?).with("rpmbuild-md5").returns(true)
        PluginPackager.stubs(:build_tool?).with("rpmbuild").returns(true)
        @plugin = mock()
        @plugin.stubs(:iteration).returns("1")
        @plugin.stubs(:metadata).returns({:name => "test", :version => "1"})
      end

      after :all do
        @tmpdirs.each{|tmpdir| FileUtils.rm_rf tmpdir if File.directory? tmpdir}
      end

      describe "#initialize" do

        it "should raise and exception if neither rpmbuild or rpmbuild-md5 is installed is not present" do
          PluginPackager.expects(:build_tool?).with("rpmbuild-md5").returns(false)
          PluginPackager.expects(:build_tool?).with("rpmbuild").returns(false)
          expect{
            RpmpackagePackager.new("plugin")
          }.to raise_exception(RuntimeError, "creating rpms require 'rpmbuild' or 'rpmbuild-md5' to be installed")
        end

        it "should set the correct libdir" do
          packager = RpmpackagePackager.new("plugin")
          packager.libdir.should == "/usr/libexec/mcollective/mcollective/"

          packager = RpmpackagePackager.new("plugin", "/tmp/")
          packager.libdir.should == "/tmp/"
        end

      end

      describe "#create_packages" do
        before :each do
          @packager = RpmpackagePackager.new(@plugin)
          @packager.tmpdir = maketmpdir
          @packager.stubs(:create_package)
          @packager.stubs(:cleanup_tmpdirs)
          @plugin.stubs(:packagedata).returns(:test => {:files => ["test.rb"]})
          @packager.stubs(:prepare_tmpdirs)
          Dir.stubs(:mktmpdir)
        end

        it "should set the package instance variables" do
          @packager.create_packages
          @packager.current_package_type.should == :test
          @packager.current_package_data.should == {:files => ["test.rb"]}
          @packager.current_package_name.should == "mcollective-test-test"
        end

        it "should create the build dir" do
          @packager.expects(:prepare_tmpdirs)
          @packager.create_packages
        end

        it "should create packages" do
          @packager.expects(:create_package)
          @packager.create_packages
        end

      end

      describe "#create_package" do
        before :each do
          @packager = RpmpackagePackager.new(@plugin)
        end

        it "should create the package" do
          PluginPackager.expects(:safe_system).with("rpmbuild -ba   /tmp/SPECS/test.spec --buildroot /tmp/BUILD")
          FileUtils.expects(:cp).twice
          @packager.tmpdir = "/tmp"
          @packager.verbose = "true"
          @packager.expects(:make_spec_file)
          @packager.current_package_name = "mcollective-testplugin-test"
          @packager.expects(:puts).with('Created RPM and SRPM packages for mcollective-testplugin-test')
          @packager.create_package(:test, {:files => ["foo.rb"]})
        end

        it "should sign the package if a signature is given" do
          PluginPackager.expects(:safe_system).with("rpmbuild -ba  --sign /tmp/SPECS/test.spec --buildroot /tmp/BUILD")
          FileUtils.expects(:cp).twice
          @packager.signature = true
          @packager.tmpdir = "/tmp"
          @packager.verbose = "true"
          @packager.expects(:make_spec_file)
          @packager.current_package_name = "mcollective-testplugin-test"
          @packager.expects(:puts).with('Created RPM and SRPM packages for mcollective-testplugin-test')
          @packager.create_package(:test, {:files => ["foo.rb"]})
        end

        it "should raise an error if the package can't be built" do
          @packager = RpmpackagePackager.new(@plugin)
          @packager.expects(:make_spec_file)
          PluginPackager.stubs(:do_quietly?).raises("foo")
          expect{
            @packager.create_package("", "")
          }.to raise_error(RuntimeError, "Could not build package. Reason - foo")
        end
      end

      describe "#make_spec_file" do
        before :each do
          @packager = RpmpackagePackager.new("package")
        end

        it "should raise an exception if specfile cannot be built" do
          File.expects(:dirname).raises("test error")
          expect{
            @packager.make_spec_file
          }.to raise_error(RuntimeError, "Could not create specfile - test error")
        end

        it "should create the specfile from the erb" do
          File.stubs(:read).returns("specfile")
          @packager.current_package_type = "test"
          @packager.tmpdir = maketmpdir
          Dir.mkdir(File.join(@packager.tmpdir, "SPECS"))
          @packager.make_spec_file
          File.read(File.join(@packager.tmpdir, "SPECS", "test.spec")).should == "specfile"
        end
      end

      describe "#prepare_tmpdirs" do
        it "should create the tmp dirs and cp the package files" do
          @plugin.stubs(:target_path).returns("")
          packager = RpmpackagePackager.new(@plugin)
          packager.expects(:make_rpm_dirs)
          FileUtils.expects(:mkdir_p)
          File.stubs(:join).returns("/target")
          FileUtils.expects(:cp_r).with("test.rb", "/target")
          packager.prepare_tmpdirs({:files => ["test.rb"]})
        end
      end

      describe "#make_rpm_dirs" do
        before :each do
          @packager = RpmpackagePackager.new("package")
        end

        it "should raise an exception if a directory can't be created" do
          File.expects(:join).raises("test error")
          expect{
            @packager.make_rpm_dirs
          }.to raise_error(RuntimeError, "Could not create BUILD directory - test error")
        end

        it "should create the correct RPM build directories" do
          @packager.tmpdir = maketmpdir
          @packager.make_rpm_dirs
          File.directory?(File.join(@packager.tmpdir, "SPECS")).should == true
          File.directory?(File.join(@packager.tmpdir, "SOURCES")).should == true
          File.directory?(File.join(@packager.tmpdir, "SRPMS")).should == true
          File.directory?(File.join(@packager.tmpdir, "BUILD")).should == true
          File.directory?(File.join(@packager.tmpdir, "RPMS")).should == true
        end
      end

      describe "#cleanup_tmpdirs" do
        it "should remove the temp directories" do
          packager = RpmpackagePackager.new("package")
          packager.tmpdir = maketmpdir
          packager.cleanup_tmpdirs
          File.directory?(packager.tmpdir).should == false
        end
      end
    end
  end
end
