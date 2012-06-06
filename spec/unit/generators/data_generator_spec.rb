#! /usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Generators
      describe DataGenerator do

        before :each do
          DataGenerator.stubs(:create_metadata_string).returns("meta\n")
        end

        describe "#create_ddl" do
          it "create the correct ddl string" do
            DataGenerator.any_instance.stubs(:create_plugin_content)
            DataGenerator.any_instance.stubs(:create_plugin_string)
            DataGenerator.any_instance.stubs(:write_plugins)

            ddl = DataGenerator.new("foo", ["output"]).ddl
            expected = File.read(File.join(File.dirname(__FILE__), "snippets", "data_ddl")).chop
            ddl.should == expected
          end
        end

        describe "#create_plugin_content" do
          it "should create the correct plugin content" do
            DataGenerator.any_instance.stubs(:create_ddl)
            DataGenerator.any_instance.stubs(:create_plugin_string)
            DataGenerator.any_instance.stubs(:write_plugins)

            ddl = DataGenerator.new("foo", ["output"]).content
            ddl.should == "      query do |what|\n        result[:output] = nil\n      end\n"
          end
        end
      end
  end
end
