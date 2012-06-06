#!/usr/bin/env rspec

require "spec_helper"

module MCollective
  module Generators
    describe Base do
      before :each do
        @erb = mock
        @erb.stubs(:result)
        File.stubs(:dirname).returns("/tmp")
        @base = Base.new(nil, nil, nil, nil, nil, nil, nil)
      end

      describe "#initialize" do
        it "should set the correct metaparameters" do
          res = Base.new("name", "description", "author", "license", "version", "url", "timeout")
          res.meta.should == {:name => "name",
                              :description => "description",
                              :author => "author",
                              :license => "license",
                              :version => "version",
                              :url => "url",
                              :timeout => "timeout"}
        end
      end

      describe "#create_metadata_string" do
        it "should load the ddl template if it is present" do
          File.expects(:read).returns("ddl")
          ERB.expects(:new).with("ddl", nil, "-").returns(@erb)
          @base.create_metadata_string
        end

        it "should raise an error if the template is not present" do
          File.expects(:read).raises(Errno::ENOENT)
          expect{
            @base.create_metadata_string
          }.to raise_error Errno::ENOENT
        end
      end

      describe "#create_plugin_string " do
        it "should load the plugin template if it is present" do
          File.expects(:read).returns("plugin")
          ERB.expects(:new).with("plugin", nil, "-").returns(@erb)
          @base.create_plugin_string
        end

        it "should raise an error if the template is not present" do
          File.expects(:read).raises(Errno::ENOENT)
          expect{
            @base.create_plugin_string
          }.to raise_error Errno::ENOENT
        end
      end

      describe "#write_plugins" do
        it "should fail if the directory already exists" do
          Dir.expects(:mkdir).raises(Errno::EEXIST)
          @base.plugin_name = "foo"
          expect{
            @base.write_plugins
          }.to raise_error RuntimeError
        end

        it "should create the directory and the plugin files if it doesn't exist" do
          Dir.stubs(:pwd).returns("/tmp")
          @base.stubs(:puts)

          Dir.expects(:mkdir).with("foo")
          Dir.expects(:mkdir).with("foo/agent")
          File.expects(:open).with("foo/agent/foo.ddl", "w")
          File.expects(:open).with("foo/agent/foo.rb", "w")

          @base.plugin_name = "foo"
          @base.mod_name = "agent"
          @base.write_plugins
        end
      end
    end
  end
end
