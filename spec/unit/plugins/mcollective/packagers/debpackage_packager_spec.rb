#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/pluginpackager/debpackage_packager.rb'

module MCollective
  module PluginPackager
    describe DebpackagePackager do

      let(:maketmpdir) do
        tmpdir = Dir.mktmpdir("mc-test")
        @tmpdirs << tmpdir
        tmpdir
      end

      before :all do
        @tmpdirs = []
      end

      before :each do
        PluginPackager.stubs(:build_tool?).with("debuild").returns(true)
        @plugin = mock()
        @plugin.stubs(:mcname).returns("mcollective")
      end

      after :all do
        @tmpdirs.each{|tmpdir| FileUtils.rm_rf tmpdir if File.directory? tmpdir}
      end

      describe "#initialize" do
        it "should raise an exception if debuild isn't present" do
          PluginPackager.expects(:build_tool?).with("debuild").returns(false)
          expect{
            DebpackagePackager.new("plugin")
          }.to raise_error(RuntimeError, "package 'debuild' is not installed")
        end

        it "should set the correct libdir and verbose value" do
          PluginPackager.expects(:build_tool?).with("debuild").returns(true)
          packager = DebpackagePackager.new("plugin", nil, nil, true)
          packager.libdir.should == "/usr/share/mcollective/plugins/mcollective/"
          packager.verbose.should == true
        end
      end

      describe "#create_packages" do
        before :each do
          @packager = DebpackagePackager.new(@plugin)
          @plugin.stubs(:packagedata).returns({:test => {:files => ["test.rb"]}})
          @plugin.stubs(:metadata).returns({:name => "test_plugin", :version => "1"})
          @plugin.stubs(:iteration).returns("1")
          @packager.stubs(:prepare_tmpdirs)
          @packager.stubs(:create_package)
          @packager.stubs(:move_packages)
          @packager.stubs(:cleanup_tmpdirs)
          Dir.stubs(:mktmpdir).with("mcollective_packager").returns("/tmp")
          Dir.stubs(:mkdir)
        end

        it "should set the package instance variables" do
          @packager.create_packages
          @packager.current_package_type.should == :test
          @packager.current_package_data.should == {:files => ["test.rb"]}
          @packager.current_package_shortname.should == "mcollective-test_plugin-test"
          @packager.current_package_fullname.should == "mcollective-test_plugin-test_1-1"
        end

        it "Should create the build dir" do
          Dir.expects(:mkdir).with("/tmp/mcollective-test_plugin-test_1")
          @packager.create_packages
        end

        it "should create packages" do
          @packager.expects(:create_package)
          @packager.create_packages
        end
      end

      describe "#create_package" do
        it "should raise an exception if the package cannot be created" do
          packager = DebpackagePackager.new(@plugin)
          packager.stubs(:create_file).raises("test exception")
          expect{
            packager.create_package
          }.to raise_error(RuntimeError, "Could not build package - test exception")
        end

        it "should correctly create a package" do
          packager = DebpackagePackager.new(@plugin, nil, nil, true)

          packager.expects(:create_file).with("control")
          packager.expects(:create_file).with("Makefile")
          packager.expects(:create_file).with("compat")
          packager.expects(:create_file).with("rules")
          packager.expects(:create_file).with("copyright")
          packager.expects(:create_file).with("changelog")
          packager.expects(:create_tar)
          packager.expects(:create_install)
          packager.expects(:create_preandpost_install)

          packager.build_dir = "/tmp"
          packager.tmpdir = "/tmp"
          packager.current_package_fullname = "test"
          PluginPackager.expects(:safe_system).with("debuild -i -us -uc")
          packager.expects(:puts).with("Created package test")

          packager.create_package
        end

        it "should add a signature if one is given" do
          packager = DebpackagePackager.new(@plugin, nil, "test", true)

          packager.expects(:create_file).with("control")
          packager.expects(:create_file).with("Makefile")
          packager.expects(:create_file).with("compat")
          packager.expects(:create_file).with("rules")
          packager.expects(:create_file).with("copyright")
          packager.expects(:create_file).with("changelog")
          packager.expects(:create_tar)
          packager.expects(:create_install)
          packager.expects(:create_preandpost_install)

          packager.build_dir = "/tmp"
          packager.tmpdir = "/tmp"
          packager.current_package_fullname = "test"
          PluginPackager.expects(:safe_system).with("debuild -i -ktest")
          packager.expects(:puts).with("Created package test")

          packager.create_package
        end
      end

      describe "#create_preandpost_install" do
        before :each do
          @packager = DebpackagePackager.new(@plugin)
        end

        it "should raise an exception if preinstall is not null and preinstall script isn't present" do
          @plugin.stubs(:preinstall).returns("myscript")
          File.expects(:exists?).with("myscript").returns(false)
          expect{
            @packager.create_preandpost_install
          }.to raise_error(RuntimeError, "pre-install script 'myscript' not found")
        end

        it "should raise an exception if postinstall is not null and postinstall script isn't present" do
          @plugin.stubs(:preinstall).returns(nil)
          @plugin.stubs(:postinstall).returns("myscript")
          File.expects(:exists?).with("myscript").returns(false)
          expect{
            @packager.create_preandpost_install
          }.to raise_error(RuntimeError, "post-install script 'myscript' not found")
        end

        it "should copy the preinstall and postinstall scripts to the correct directory with the correct name" do
          @plugin.stubs(:postinstall).returns("myscript")
          @plugin.stubs(:preinstall).returns("myscript")
          @packager.build_dir = "/tmp/"
          @packager.current_package_shortname = "test"
          File.expects(:exists?).with("myscript").twice.returns(true)
          FileUtils.expects(:cp).with("myscript", "/tmp/debian/test.preinst")
          FileUtils.expects(:cp).with("myscript", "/tmp/debian/test.postinst")
          @packager.create_preandpost_install
        end
      end

      describe "#create_install" do
        before :each do
          @packager = DebpackagePackager.new(@plugin)
          @plugin.stubs(:path).returns("")
        end

        it "should raise an exception if the install file can't be created" do
          File.expects(:join).raises("test error")
          expect{
            @packager.create_install
          }.to raise_error(RuntimeError, "Could not create install file - test error")
        end

        it "should copy the package install file to the correct location" do
          tmpdir = maketmpdir
          Dir.mkdir(File.join(tmpdir, "debian"))
          @packager.build_dir = tmpdir
          @packager.current_package_shortname = "test"
          @packager.current_package_data = {:files => ["foo.rb"]}
          @packager.create_install
          install_file = File.read("#{tmpdir}/debian/test.install")
          install_file.should == "/usr/share/mcollective/plugins/mcollective/foo.rb /usr/share/mcollective/plugins/mcollective\n"
        end
      end

      describe "#move_packages" do
        before :each do
          @plugin = mock()
        end

        it "should move the packages to the working directory" do
          Dir.expects(:glob)
          File.expects(:join)
          FileUtils.expects(:cp)
          @packager = DebpackagePackager.new(@plugin) 
          @packager.move_packages
        end

        it "should raise an error if the packages could not be moved" do
          @packager = DebpackagePackager.new(@plugin)
          File.expects(:join).raises("error")
          expect{
            @packager.move_packages
          }.to raise_error RuntimeError, "Could not copy packages to working directory: 'error'"
        end
      end

      describe "#create_tar" do
        before :each do
          @packager = DebpackagePackager.new(@plugin, nil, true)
        end

        it "should raise an exception if the tarball can't be built" do
          PluginPackager.expects(:do_quietly?).raises("test error")
          expect{
            @packager.create_tar
          }.to raise_error(RuntimeError, "Could not create tarball - test error")
        end

        it "should create a tarball containing the package files" do
          @packager.tmpdir = "/tmp"
          @packager.build_dir = "/build_dir"
          @packager.current_package_shortname = "test"
          @plugin.stubs(:metadata).returns(@plugin)
          @plugin.stubs(:[]).with(:version).returns("1")
          @plugin.stubs(:iteration).returns("1")
          PluginPackager.expects(:safe_system).with("tar -Pcvzf /tmp/test_1.orig.tar.gz test_1")
          @packager.create_tar
        end
      end

      describe "#create_file" do
        before :each do
          @packager = DebpackagePackager.new(@plugin)
        end

        it "should raise an exception if the file can't be created" do
          File.expects(:dirname).raises("test error")
          expect{
            @packager.create_file("test")
          }.to raise_error(RuntimeError, "could not create test file - test error")
        end

        it "should place a build file in the debian directory" do
          tmpdir = maketmpdir
          Dir.mkdir(File.join(tmpdir, "debian"))
          @packager.build_dir = tmpdir
          File.expects(:read).returns("testfile")
          @packager.create_file("testfile")
          File.unstub(:read)
          result = File.read(File.join(tmpdir, "debian", "testfile"))
          result.stubs(:result)
          result.should == "testfile\n"
        end
      end

      describe "#prepare_tmpdirs" do
        before :each do
          @tmpfile = Tempfile.new("mc-file").path
        end

        after :each do
          FileUtils.rm(@tmpfile)
        end

        it "should create the correct tmp dirs and copy package contents to correct dir" do
          packager = DebpackagePackager.new(@plugin)
          tmpdir = maketmpdir
          packager.build_dir = tmpdir
          @plugin.stubs(:target_path).returns("")

          packager.prepare_tmpdirs({:files => [@tmpfile]})
          File.directory?(tmpdir).should == true
          File.directory?(File.join(tmpdir, "debian")).should == true
          File.exists?(File.join(tmpdir, packager.libdir, "tmp", File.basename(@tmpfile))).should == true
        end
      end

      describe "#cleanup_tmpdirs" do
        before :all do
          @tmpdir = maketmpdir
        end

        before :each do
          @packager = DebpackagePackager.new(@plugin)
        end

        it "should cleanup temp directories" do
          @packager.tmpdir = @tmpdir
          @packager.cleanup_tmpdirs
          File.directory?(@tmpdir).should == false
        end

        it "should not delete any directories if @tmpdir isn't present" do
          @packager = DebpackagePackager.new(@plugin)
          @packager.tmpdir = rand.to_s
          FileUtils.expects(:rm_r).never
          @packager.cleanup_tmpdirs
        end
      end
    end
  end
end
