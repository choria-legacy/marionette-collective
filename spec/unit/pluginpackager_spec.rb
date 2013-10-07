#!/usr/bin/enn rspec

require 'spec_helper'

module MCollective
  describe PluginPackager do
    describe "#load_packagers" do
      it "should load all PluginPackager plugins" do
        PluginManager.expects(:find_and_load).with("pluginpackager")
        PluginPackager.load_packagers
      end
    end

    describe "#[]" do
      it "should return the correct class" do
        PluginPackager.expects(:const_get).with("Foo").returns(:foo)
        result = PluginPackager["Foo"]
        result.should == :foo
      end

      it "should do something else" do
        expect{
          PluginPackager["Bar"]
        }.to raise_error(NameError, 'uninitialized constant MCollective::PluginPackager::Bar')
      end
    end

    describe "#get_metadata" do
      it "should raise an exception if the ddl file can't be loaded" do
        DDL.expects(:new).with("package", :foo, false)
        File.stubs(:join)
        Dir.stubs(:glob).returns('')
        expect{
          PluginPackager.get_metadata("/tmp", "foo")
        }.to raise_error(RuntimeError)
      end

      it "should load the ddl file and return the metadata" do
        ddl = mock
        DDL.expects(:new).with("package", :foo, false).returns(ddl)
        File.stubs(:join)
        Dir.stubs(:glob).returns(["foo.ddl"])
        File.expects(:read).with("foo.ddl").returns("foo_ddl")
        ddl.expects(:instance_eval).with("foo_ddl")
        ddl.expects(:meta).returns("metadata")
        ddl.expects(:requirements).returns({:mcollective => 1})

        meta, requirements = PluginPackager.get_metadata("/tmp", "foo")
        meta.should == "metadata"
        requirements.should == 1
      end
    end

    describe "#check_dir_present" do
      it "should return true if the directory is present and not empty" do
        File.expects(:directory?).with("/tmp").returns(true)
        File.expects(:join).with("/tmp", "*")
        Dir.expects(:glob).returns([1])
        result = PluginPackager.check_dir_present("/tmp")
        result.should == true
      end

      it "should return false if the directory is not present" do
        File.expects(:directory?).with("/tmp").returns(false)
        result = PluginPackager.check_dir_present("/tmp")
        result.should == false
      end

      it "should return false if the direcotry is present but empty" do
        File.expects(:directory?).with("/tmp").returns(true)
        File.expects(:join).with("/tmp", "*")
        Dir.expects(:glob).returns([])
        result = PluginPackager.check_dir_present("/tmp")
        result.should == false
      end
    end

    describe "#execute_verbosely" do
      it "should call the block parameter if verbose is true" do
        result = PluginPackager.execute_verbosely(true) {:success}
        result.should == :success
      end

      it "should call the block parameter quietly if verbose is false" do
        std_out = Tempfile.new("mc_pluginpackager_spec")
        File.expects(:new).with("/dev/null", "w").returns(std_out)
        PluginPackager.execute_verbosely(false) {puts "success"}
        std_out.rewind
        std_out.read.should == "success\n"
        std_out.close
        std_out.unlink
      end

      it "should raise an exception and reset stdout if the block raises an execption" do
        expect{
          PluginPackager.execute_verbosely(false) {raise Exception, "exception"}
        }.to raise_error(Exception, "exception")
      end
    end

    describe "#command_available?" do
      it "should return true if the given build tool is present on the system" do
        File.expects(:join).returns("foo")
        File.expects(:exists?).with("foo").returns(true)
        result = PluginPackager.command_available?("foo")
        result.should == true
      end

      it "should return false if the given build tool is not present on the system" do
        File.stubs(:join).returns("foo")
        File.stubs(:exists?).with("foo").returns(false)
        result = PluginPackager.command_available?("foo")
        result.should == false
      end
    end

    describe "#safe_system" do
      it "should not raise any exceptions if a command ran" do
        PluginPackager.expects(:system).with("foo").returns(true)
        lambda{PluginPackager.safe_system("foo")}.should_not raise_error
      end

      it "should raise a RuntimeError if command cannot be run" do
        PluginPackager.expects(:system).with("foo").returns(false)
        expect{
          PluginPackager.safe_system("foo")
        }.to raise_error(RuntimeError, "Failed: foo")
      end
    end

    describe '#filter_dependencies' do
      before :each do
        @dependencies = [{:name => 'rspec', :version => '1.0'}]
      end

      it 'should leave normal dependencies intact' do
        result = PluginPackager.filter_dependencies('debian', @dependencies)
        result.should == @dependencies
      end

      it 'should filter out dependencies with the incorrect prefix' do
        @dependencies << {:name => 'redhat::rspec_redhat', :version => '2.0'}
        result = PluginPackager.filter_dependencies('debian', @dependencies)
        result.should == [{:name => 'rspec', :version => '1.0'}]
      end

      it 'should reformat dependencies with the correct prefix' do
        @dependencies << {:name => 'debian::rspec_debian', :version => '2.0'}
        result = PluginPackager.filter_dependencies('debian', @dependencies)
        result.should == [{:name => 'rspec', :version => '1.0'},
                          {:name => 'rspec_debian', :version => '2.0'}]
      end
    end
  end
end
