#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe DDL do
      before :each do
        @ddl = DDL.new("rspec", false)
      end

      describe "#findddlfile" do
        it "should construct the correct ddl file name" do
          Config.any_instance.expects(:libdir).returns(["/nonexisting"])
          File.expects("exist?").with("/nonexisting/mcollective/agent/foo.ddl").returns(false)

          @ddl.findddlfile("foo").should == false
        end

        it "should check each libdir for a ddl file" do
          Config.any_instance.expects(:libdir).returns(["/nonexisting1", "/nonexisting2"])
          File.expects("exist?").with("/nonexisting1/mcollective/agent/foo.ddl").returns(false)
          File.expects("exist?").with("/nonexisting2/mcollective/agent/foo.ddl").returns(false)

          @ddl.findddlfile("foo").should == false
        end

        it "should return the ddl file path if found" do
          Config.any_instance.expects(:libdir).returns(["/nonexisting"])
          File.expects("exist?").with("/nonexisting/mcollective/agent/foo.ddl").returns(true)
          Log.expects(:debug).with("Found foo ddl at /nonexisting/mcollective/agent/foo.ddl")

          @ddl.findddlfile("foo").should == "/nonexisting/mcollective/agent/foo.ddl"
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
            }.to raise_error("Metadata needs a :#{tst}")
          end
        end

        it "should should allow arbitrary metadata" do
          metadata = {:name => "name", :description => "description", :author => "author", :license => "license",
                      :version => "version", :url => "url", :timeout => "timeout", :foo => "bar"}

          @ddl.metadata(metadata)
          @ddl.meta.should == metadata
        end
      end

      describe "#action" do
        it "should ensure a description is set" do
          expect {
            @ddl.action("act", {})
          }.to raise_error("Action needs a :description")
        end

        it "should create a default action structure" do
          @ddl.action("act", :description => "rspec")

          action = @ddl.action_interface("act")

          action.class.should == Hash
          action[:action].should == "act"
          action[:input].should == {}
          action[:output].should == {}
          action[:display].should == :failed
          action[:description].should == "rspec"
        end

        it "should call a block if one is given and set the correct action name" do
          @ddl.action("act", :description => "rspec") { @ddl.instance_variable_get("@current_action").should == "act" }
        end
      end

      describe "#input" do
        it "should ensure required properties are set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)

          [:prompt, :description, :type, :optional].each do |arg|
            args = {:prompt => "prompt", :description => "descr", :type => "type", :optional => true}
            args.delete(arg)

            expect {
              @ddl.input(:test, args)
            }.to raise_error("Input needs a :#{arg}")
          end

          @ddl.input(:test, {:prompt => "prompt", :description => "descr", :type => "type", :optional => true})
        end

        it "should ensure strings have a validation and maxlength" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)

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
          @ddl.instance_variable_set("@current_action", :test)

          expect {
            @ddl.input(:test, :prompt => "prompt", :description => "descr",
                       :type => :list, :optional => true)
          }.to raise_error("Input type :list needs a :list argument")

          @ddl.input(:test, :prompt => "prompt", :description => "descr",
                     :type => :list, :optional => true, :list => [])
        end

        it "should save correct data for a list input" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)
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
          @ddl.instance_variable_set("@current_action", :test)
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
          @ddl.instance_variable_set("@current_action", :test)

          expect {
            @ddl.output(:test, {})
          }.to raise_error("Output test needs a description argument")
        end

        it "should ensure a :display_as is set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)

          expect {
            @ddl.output(:test, {:description => "rspec"})
          }.to raise_error("Output test needs a display_as argument")
        end

        it "should save correct data for an output" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)

          @ddl.output(:test, {:description => "rspec", :display_as => "RSpec"})

          action = @ddl.action_interface(:test)

          action[:output][:test][:description].should == "rspec"
          action[:output][:test][:display_as].should == "RSpec"
        end
      end

      describe "#display" do
        it "should ensure a valid display property is set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)

          [:ok, :failed, :flatten, :always].each do |display|
            @ddl.display(display)

            action = @ddl.action_interface(:test)
            action[:display].should == display
          end

          expect {
            @ddl.display(:foo)
          }.to raise_error("Display preference foo is not valid, should be :ok, :failed, :flatten or :always")
        end
      end

      describe "#help" do
        it "should correctly execute the template with a valid binding" do
          @ddl.instance_variable_set("@meta", "meta")
          @ddl.instance_variable_set("@actions", "actions")
          IO.expects(:read).with("/template").returns("<%= meta %>:<%= actions %>")
          @ddl.help("/template").should == "meta:actions"
        end
      end

      describe "#actions" do
        it "should return the correct list of actions" do
          @ddl.action(:test1, :description => "rspec")
          @ddl.action(:test2, :description => "rspec")

          @ddl.actions.sort.should == [:test1, :test2]
        end
      end

      describe "#action_interface" do
        it "should return the correct interface" do
          @ddl.action(:test1, :description => "rspec")
          @ddl.action_interface(:test1).should == {:description=>"rspec", :output=>{}, :input=>{}, :action=>:test1, :display=>:failed}
        end
      end

      describe "#validate_request" do
        it "should ensure the action is known" do
          @ddl.action(:test, :description => "rspec")

          expect {
            @ddl.validate_request(:fail, {})
          }.to raise_error("Attempted to call action fail for rspec but it's not declared in the DDL")

          @ddl.validate_request(:test, {})
        end

        it "should check all required arguments are present" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)
          @ddl.input(:optional, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)
          @ddl.input(:required, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => false, :validation => "",
                     :maxlength => 1)

          expect {
            @ddl.validate_request(:test, {})
          }.to raise_error("Action test needs a required argument")

          @ddl.validate_request(:test, {:required => "f"}).should == true
        end

        it "should ensure strings are String" do
          @ddl.action(:string, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :string)
          @ddl.input(:string, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)

          expect {
            @ddl.validate_request(:string, {:string => 1})
          }.to raise_error("Input string should be a string")

          @ddl.validate_request(:string, {:string => "1"})
        end

        it "should ensure strings are not longer than maxlength" do
          @ddl.action(:string, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :string)
          @ddl.input(:string, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)

          expect {
            @ddl.validate_request(:string, {:string => "too long"})
          }.to raise_error("Input string is longer than 1 character(s)")

          @ddl.validate_request(:string, {:string => "1"})
        end

        it "should validate strings using regular expressions" do
          @ddl.action(:string, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :string)
          @ddl.input(:string, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "^regex$",
                     :maxlength => 100)

          expect {
            @ddl.validate_request(:string, {:string => "doesnt validate"})
          }.to raise_error("Input string does not match validation regex ^regex$")

          @ddl.validate_request(:string, {:string => "regex"})
        end

        it "should validate list arguments correctly" do
          @ddl.action(:list, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :list)
          @ddl.input(:list, :prompt => "prompt", :description => "descr",
                     :type => :list, :optional => true, :list => [1,2])

          expect {
            @ddl.validate_request(:list, {:list => 3})
          }.to raise_error("Input list doesn't match list 1, 2")

          @ddl.validate_request(:list, {:list => 1})
        end

        it "should validate boolean arguments correctly" do
          @ddl.action(:bool, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :bool)
          @ddl.input(:bool, :prompt => "prompt", :description => "descr",
                     :type => :boolean, :optional => true)

          expect {
            @ddl.validate_request(:bool, {:bool => 3})
          }.to raise_error("Input bool should be a boolean")

          @ddl.validate_request(:bool, {:bool => true})
          @ddl.validate_request(:bool, {:bool => false})
        end

        it "should validate integer arguments correctly" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)
          @ddl.input(:int, :prompt => "prompt", :description => "descr",
                     :type => :integer, :optional => true)

          expect {
            @ddl.validate_request(:test, {:int => "1"})
          }.to raise_error("Input int should be a integer")

          expect {
            @ddl.validate_request(:test, {:int => 1.1})
          }.to raise_error("Input int should be a integer")

          @ddl.validate_request(:test, {:int => 1})
        end

        it "should validate float arguments correctly" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)
          @ddl.input(:float, :prompt => "prompt", :description => "descr",
                     :type => :float, :optional => true)

          expect {
            @ddl.validate_request(:test, {:float => "1"})
          }.to raise_error("Input float should be a floating point number")

          expect {
            @ddl.validate_request(:test, {:float => 1})
          }.to raise_error("Input float should be a floating point number")

          @ddl.validate_request(:test, {:float => 1.1})
        end

        it "should validate number arguments correctly" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_action", :test)
          @ddl.input(:number, :prompt => "prompt", :description => "descr",
                     :type => :number, :optional => true)

          expect {
            @ddl.validate_request(:test, {:number => "1"})
          }.to raise_error("Input number should be a number")

          @ddl.validate_request(:test, {:number => 1})
          @ddl.validate_request(:test, {:number => 1.1})
        end
      end
    end
  end
end
