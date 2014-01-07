#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module DDL
    describe Base do
      before :each do
        Cache.delete!(:ddl) rescue nil
        @ddl = DDL.new("rspec", :agent, false)
        @ddl.metadata(:name => "name", :description => "description", :author => "author", :license => "license", :version => "version", :url => "url", :timeout => "timeout")
      end

      describe "#template_for_plugintype" do
        it "should return the backward compat path for agent ddls" do
          @ddl.template_for_plugintype.should == "rpc-help.erb"
        end

        it "should return correct new path for other ddls" do
          @ddl.instance_variable_set("@plugintype", :data)
          @ddl.stubs(:helptemplatedir).returns("/etc/mcollective")
          Util.stubs(:templatepath).with("data-help.erb").returns("/etc/mcollective/data-help.erb")
          File.expects(:exists?).with("/etc/mcollective/data-help.erb").returns(true)
          @ddl.template_for_plugintype.should == "data-help.erb"
        end
      end

      describe "#help" do
        it "should use conventional template paths when none is provided" do
          File.expects(:read).with("/etc/mcollective/rpc-help.erb").returns("rspec")
          File.expects(:read).with("/etc/mcollective/metadata-help.erb").returns("rspec")
          @ddl.help.should == "rspec"
        end

        it "should use template from help template path when provided template name is not an absolute file path" do
          Util.stubs(:absolute_path?).returns(false)
          Util.stubs(:templatepath).returns("/etc/mcollective/foo", "/etc/mcollective/metadata-help.erb")
          File.expects(:read).with("/etc/mcollective/foo").returns("rspec")
          File.expects(:read).with("/etc/mcollective/metadata-help.erb").returns("rspec")
          @ddl.help("foo").should == "rspec"
        end

        it "should use supplied template path when one is provided" do
          File.expects(:read).with("/foo").returns("rspec")
          File.expects(:read).with("/etc/mcollective/metadata-help.erb").returns("rspec")
          @ddl.help("/foo").should == "rspec"
        end

        it "should correctly execute the template with a valid binding" do
          @ddl.instance_variable_set("@meta", "meta")
          @ddl.instance_variable_set("@entities", "actions")
          File.expects(:read).with("/template").returns("<%= meta %>:<%= entities %>")
          File.expects(:read).with("/etc/mcollective/metadata-help.erb").returns("rspec")
          @ddl.help("/template").should == "meta:actions"
        end
      end

      describe "#validate_input_arguments" do
        before :all do
          Config.instance.stubs(:configured).returns(true)
          Config.instance.stubs(:libdir).returns([File.join(File.dirname(__FILE__), "../../../plugins")])
        end

        it "should ensure strings are String" do
          @ddl.action(:string, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :string)
          @ddl.input(:string, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:string][:input], :string, 1)
          }.to raise_error("Cannot validate input string: value should be a string")

          @ddl.validate_input_argument(@ddl.entities[:string][:input], :string, "1")
        end

        it "should ensure strings are not longer than maxlength" do
          @ddl.action(:string, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :string)
          @ddl.input(:string, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:string][:input], :string, "too long")
          }.to raise_error("Cannot validate input string: Input string is longer than 1 character(s)")

          @ddl.validate_input_argument(@ddl.entities[:string][:input], :string, "1")
        end

        it "should validate strings using regular expressions" do
          @ddl.action(:string, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :string)
          @ddl.input(:string, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "^regex$",
                     :maxlength => 100)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:string][:input], :string, "doesnt validate")
          }.to raise_error("Cannot validate input string: value should match ^regex$")

          @ddl.validate_input_argument(@ddl.entities[:string][:input], :string, "regex")
        end

        it "should validate list arguments correctly" do
          @ddl.action(:list, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :list)
          @ddl.input(:list, :prompt => "prompt", :description => "descr",
                     :type => :list, :optional => true, :list => [1,2])

          expect {
            @ddl.validate_input_argument(@ddl.entities[:list][:input], :list, 3)
          }.to raise_error("Cannot validate input list: value should be one of 1, 2")

          @ddl.validate_input_argument(@ddl.entities[:list][:input], :list, 1)
        end

        it "should validate boolean arguments correctly" do
          @ddl.action(:bool, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :bool)
          @ddl.input(:bool, :prompt => "prompt", :description => "descr",
                     :type => :boolean, :optional => true)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:bool][:input], :bool, 3)
          }.to raise_error("Cannot validate input bool: value should be a boolean")

          @ddl.validate_input_argument(@ddl.entities[:bool][:input], :bool, true)
          @ddl.validate_input_argument(@ddl.entities[:bool][:input], :bool, false)
        end

        it "should validate integer arguments correctly" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:int, :prompt => "prompt", :description => "descr",
                     :type => :integer, :optional => true)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:test][:input], :int, "1")
          }.to raise_error("Cannot validate input int: value should be a integer")

          expect {
            @ddl.validate_input_argument(@ddl.entities[:test][:input], :int, 1.1)
          }.to raise_error("Cannot validate input int: value should be a integer")

          @ddl.validate_input_argument(@ddl.entities[:test][:input], :int, 1)
        end

        it "should validate float arguments correctly" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:float, :prompt => "prompt", :description => "descr",
                     :type => :float, :optional => true)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:test][:input], :float, "1")
          }.to raise_error("Cannot validate input float: value should be a float")

          expect {
            @ddl.validate_input_argument(@ddl.entities[:test][:input], :float, 1)
          }.to raise_error("Cannot validate input float: value should be a float")

          @ddl.validate_input_argument(@ddl.entities[:test][:input], :float, 1.1)
        end

        it "should validate number arguments correctly" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:number, :prompt => "prompt", :description => "descr",
                     :type => :number, :optional => true)

          expect {
            @ddl.validate_input_argument(@ddl.entities[:test][:input], :number, "1")
          }.to raise_error("Cannot validate input number: value should be a number")

          @ddl.validate_input_argument(@ddl.entities[:test][:input], :number, 1)
          @ddl.validate_input_argument(@ddl.entities[:test][:input], :number, 1.1)
        end
      end

      describe "#requires" do
        it "should only accept hashes as arguments" do
          expect { @ddl.requires(1) }.to raise_error(/should be a hash/)
        end

        it "should only accept valid requirement types" do
          expect { @ddl.requires(:rspec => "1") }.to raise_error(/is not a valid requirement/)
          @ddl.requires(:mcollective => "1.0.0")
        end

        it "should save the requirement" do
          @ddl.requires(:mcollective => "1.0.0")

          @ddl.requirements.should == {:mcollective => "1.0.0"}
        end
      end

      describe "#validate_requirements" do
        it "should fail for older versions of mcollective" do
          Util.stubs(:mcollective_version).returns("0.1")
          expect { @ddl.requires(:mcollective => "2.0") }.to raise_error(/requires.+version 2.0/)
        end

        it "should pass for newer versions of mcollective" do
          Util.stubs(:mcollective_version).returns("2.0")
          @ddl.requires(:mcollective => "0.1")
          @ddl.validate_requirements.should == true
        end

        it "should bypass checks in development" do
          Util.stubs(:mcollective_version).returns("@DEVELOPMENT_VERSION@")
          Log.expects(:warn).with(regexp_matches(/skipped in development/))
          @ddl.requires(:mcollective => "0.1")
        end
      end

      describe "#loaddlfile" do
        it "should raise the correct error when a ddl isnt present" do
          @ddl.expects(:findddlfile).returns(false)
          expect { @ddl.loadddlfile }.to raise_error("Can't find DDL for agent plugin 'rspec'")
        end
      end

      describe "#findddlfile" do
        it "should construct the correct ddl file name" do
          Config.instance.expects(:libdir).returns(["/nonexisting"])
          File.expects("exist?").with("/nonexisting/mcollective/agent/foo.ddl").returns(false)

          @ddl.findddlfile("foo").should == false
        end

        it "should check each libdir for a ddl file" do
          Config.instance.expects(:libdir).returns(["/nonexisting1", "/nonexisting2"])
          File.expects("exist?").with("/nonexisting1/mcollective/agent/foo.ddl").returns(false)
          File.expects("exist?").with("/nonexisting2/mcollective/agent/foo.ddl").returns(false)

          @ddl.findddlfile("foo").should == false
        end

        it "should return the ddl file path if found" do
          Config.instance.expects(:libdir).returns(["/nonexisting"])
          File.expects("exist?").with("/nonexisting/mcollective/agent/foo.ddl").returns(true)
          Log.expects(:debug).with("Found foo ddl at /nonexisting/mcollective/agent/foo.ddl")

          @ddl.findddlfile("foo").should == "/nonexisting/mcollective/agent/foo.ddl"
        end

        it "should default to the current plugin and type" do
          Config.instance.expects(:libdir).returns(["/nonexisting"])
          File.expects("exist?").with("/nonexisting/mcollective/agent/rspec.ddl").returns(true)

          @ddl.findddlfile.should == "/nonexisting/mcollective/agent/rspec.ddl"
        end
      end

      describe "#metadata" do
        it "should ensure minimum parameters are given" do
          [:name, :description, :author, :license, :version, :url, :timeout].each do |tst|
            metadata = {:name => "name", :description => "description", :author => "author",
                        :license => "license", :version => "version", :url => "url", :timeout => "timeout"}

            metadata.delete(tst)

            expect {
              @ddl.metadata(metadata)
            }.to raise_error("Metadata needs a :#{tst} property")
          end
        end

        it "should should allow arbitrary metadata" do
          metadata = {:name => "name", :description => "description", :author => "author", :license => "license",
                      :version => "version", :url => "url", :timeout => "timeout", :foo => "bar"}

          @ddl.metadata(metadata)
          @ddl.meta.should == metadata
        end
      end

      describe "#input" do
        it "should ensure required properties are set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          [:prompt, :description, :type, :optional].each do |arg|
            args = {:prompt => "prompt", :description => "descr", :type => "type", :optional => true}
            args.delete(arg)

            expect {
              @ddl.input(:test, args)
            }.to raise_error("Input needs a :#{arg} property")
          end

          @ddl.input(:test, {:prompt => "prompt", :description => "descr", :type => "type", :optional => true})
        end

        it "should ensure strings have a validation and maxlength" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          expect {
            @ddl.input(:test, :prompt => "prompt", :description => "descr",
                       :type => :string, :optional => true)
          }.to raise_error("Input type :string needs a :validation argument")

          expect {
            @ddl.input(:test, :prompt => "prompt", :description => "descr",
                       :type => :string, :optional => true, :validation => 1)
          }.to raise_error("Input type :string needs a :maxlength argument")

          @ddl.input(:test, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => 1, :maxlength => 1)
        end

        it "should ensure lists have a list argument" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          expect {
            @ddl.input(:test, :prompt => "prompt", :description => "descr",
                       :type => :list, :optional => true)
          }.to raise_error("Input type :list needs a :list argument")

          @ddl.input(:test, :prompt => "prompt", :description => "descr",
                     :type => :list, :optional => true, :list => [])
        end

        it "should save correct data for a list input" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:test, :prompt => "prompt", :description => "descr",
                     :type => :list, :optional => true, :list => [])

          action = @ddl.action_interface(:test)

          action[:input][:test][:prompt].should == "prompt"
          action[:input][:test][:description].should == "descr"
          action[:input][:test][:type].should == :list
          action[:input][:test][:optional].should == true
          action[:input][:test][:list].should == []
        end

        it "should save correct data for a string input" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:test, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)

          action = @ddl.action_interface(:test)

          action[:input][:test][:prompt].should == "prompt"
          action[:input][:test][:description].should == "descr"
          action[:input][:test][:type].should == :string
          action[:input][:test][:optional].should == true
          action[:input][:test][:validation].should == ""
          action[:input][:test][:maxlength].should == 1
        end
      end

      describe "#output" do
        it "should ensure a :description is set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          expect {
            @ddl.output(:test, {})
          }.to raise_error("Output test needs a description argument")
        end

        it "should ensure a :display_as is set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          expect {
            @ddl.output(:test, {:description => "rspec"})
          }.to raise_error("Output test needs a display_as argument")
        end

        it "should save correct data for an output" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          @ddl.output(:test, {:description => "rspec", :display_as => "RSpec", :default => "default"})

          action = @ddl.action_interface(:test)

          action[:output][:test][:description].should == "rspec"
          action[:output][:test][:display_as].should == "RSpec"
          action[:output][:test][:default].should == "default"
        end

        it "should set unsupplied defaults to our internal unset representation" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          @ddl.output(:test, {:description => "rspec", :display_as => "RSpec"})

          action = @ddl.action_interface(:test)

          action[:output][:test][:default].should == nil
        end
      end

    end
  end
end
