#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module DDL
    describe AgentDDL do
      before :each do
        Cache.delete!(:ddl) rescue nil
        @ddl = DDL.new("rspec", :agent, false)
        @ddl.metadata(:name => "name", :description => "description", :author => "author", :license => "license", :version => "version", :url => "url", :timeout => "timeout")
      end

      describe "#symbolize_basic_input_arguments" do
        before(:each) do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:test, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1, :default => "default")
        end

        it "should warn when there are string and symbol inputs for the same stringified key" do
          @ddl.input("test", :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1, :default => "default")

          Log.expects(:warn).with("String and Symbol versions of input test found in the DDL for rspec, ensure your DDL keys are unique.")
          @ddl.symbolize_basic_input_arguments(@ddl.action_interface(:test)[:input], {:test => 1, "test" => 2})
        end

        it "should use the symbol given a string argument when there is not also a matching string input" do
          result = @ddl.symbolize_basic_input_arguments(@ddl.action_interface(:test)[:input], {"test" => 2})
          expect(result).to eq(:test => 2)
        end

        it "should use the string given a string argument when there is also a matching string input" do
          @ddl.input("test", :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1, :default => "default")

          Log.stubs(:warn)
          result = @ddl.symbolize_basic_input_arguments(@ddl.action_interface(:test)[:input], {"test" => 2})
          expect(result).to eq("test" => 2)
        end

        it "should not change symbols matching symbol inputs" do
          result = @ddl.symbolize_basic_input_arguments(@ddl.action_interface(:test)[:input], {:test => 2})
          expect(result).to eq(:test => 2)
        end

        it "should not change strings matching strings inputs" do
          @ddl.input("string_test", :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1, :default => "default")

          result = @ddl.symbolize_basic_input_arguments(@ddl.action_interface(:test)[:input], {"string_test" => 2})
          expect(result).to eq("string_test" => 2)
        end
      end

      describe "#input" do
        it "should validate that an :optional property is set" do
          expect { @ddl.input(:x, {:y => 1}) }.to raise_error("Input needs a :optional property")
        end
      end

      describe "#set_default_input_arguments" do
        before do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          @ddl.input(:optional, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1, :default => "default")
          @ddl.input(:required, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => false, :validation => "",
                     :maxlength => 1, :default => "default")
        end

        it "should correctly add default arguments to required inputs" do
          args = {}

          @ddl.set_default_input_arguments(:test, args)

          args.should == {:required => "default"}
        end

        it "should not override any existing arguments" do
          args = {:required => "specified"}

          @ddl.set_default_input_arguments(:test, args)

          args.should == {:required => "specified"}
        end

        it "should detect json primitive key names and consider them present as their symbol equivelants" do
          args = {"required" => "specified"}

          @ddl.set_default_input_arguments(:test, args)

          args.should == {"required" => "specified"}
        end

        it "should not consider the string key equiv to the symbol one when both symbol and string keys exist" do
          @ddl.input("required", :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => false, :validation => "",
                     :maxlength => 1, :default => "string default")

          args = {"required" => "specified"}
          @ddl.set_default_input_arguments(:test, args)

          args.should == {"required" => "specified", :required=>"default"}
        end
      end

      describe "#validate_rpc_request" do
        before(:each) do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)
          @ddl.input(:optional, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => true, :validation => "",
                     :maxlength => 1)
          @ddl.input(:required, :prompt => "prompt", :description => "descr",
                     :type => :string, :optional => false, :validation => "",
                     :maxlength => 1)
        end

        it "should ensure the action is known" do
          expect {
            @ddl.validate_rpc_request(:fail, {})
          }.to raise_error("Attempted to call action fail for rspec but it's not declared in the DDL")

          @ddl.validate_rpc_request(:test, {:required => "f"})
        end

        it "should check all required arguments are present" do
          @ddl.stubs(:validate_input_argument).returns(true)

          expect {
            @ddl.validate_rpc_request(:test, {})
          }.to raise_error("Action test needs a required argument")

          @ddl.validate_rpc_request(:test, {:required => "f"}).should == true
        end

        it "should input validate every supplied key" do
          @ddl.expects(:validate_input_argument).with(@ddl.entities[:test][:input], :required, "f")
          @ddl.expects(:validate_input_argument).with(@ddl.entities[:test][:input], :optional, "f")

          @ddl.validate_rpc_request(:test, {:required => "f", :optional => "f"}).should == true
        end

        it "should input validate string keys for symbol inputs correctly" do
          @ddl.expects(:validate_input_argument).with(@ddl.entities[:test][:input], :required, "f")
          @ddl.expects(:validate_input_argument).with(@ddl.entities[:test][:input], :optional, "f")

          @ddl.validate_rpc_request(:test, {"required" => "f", "optional" => "f"}).should == true
        end
      end

      describe "#is_function" do
        before :each do
          PluginManager.expects(:find).with("aggregate").returns(["plugin"])
        end

        it "should return true if the aggregate function is present" do
          @ddl.is_function?("plugin").should == true
        end

        it "should return false if the aggregate function is not present" do
          @ddl.is_function?("no_plugin").should == false
        end
      end

      describe "#method_missing" do
        it "should call super if the aggregate plugin isn't present" do
          expect{
            @ddl.test
          }.to raise_error(NoMethodError)
        end

        it "should call super if @process_aggregate_function is false" do
          expect{
            result = @ddl.test(:value)
          }.to raise_error(NoMethodError)
        end

        it "should return the function hash" do
          Config.instance.mode = :client
          @ddl.instance_variable_set(:@process_aggregate_functions, true)
          result = @ddl.method_missing(:test_function, :rspec)
          result.should == {:args => [:rspec], :function => :test_function }
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

      describe "#display" do
        it "should ensure a valid display property is set" do
          @ddl.action(:test, :description => "rspec")
          @ddl.instance_variable_set("@current_entity", :test)

          [:ok, :failed, :flatten, :always].each do |display|
            @ddl.display(display)

            action = @ddl.action_interface(:test)
            action[:display].should == display
          end

          expect {
            @ddl.display(:foo)
          }.to raise_error(/Display preference foo is not valid/)
        end
      end

      describe "#summarize" do
        before :each do
          @block_result = nil
          @block = Proc.new{@block_result = :success}
        end

        after :each do
          @block_result = nil
        end

        it "should call the block parameter if config mode is not server" do
          Config.instance.mode = :client
          result = @ddl.summarize(&@block)
          @block_result.should == :success
        end

        it "should not call the block parameter if config mode is server" do
          Config.instance.mode = :server
          result = @ddl.summarize(&@block)
          @block_result.should == nil
        end
      end

      describe "#aggregate" do
        it "should raise an exception if aggregate format isn't a hash" do
          expect{
            @ddl.aggregate(:foo, :format)
          }.to raise_error(DDLValidationError, "Formats supplied to aggregation functions should be a hash")
        end

        it "should raise an exception if format hash does not include a :format key" do
          expect{
            @ddl.aggregate(:foo, {})
          }.to raise_error(DDLValidationError, "Formats supplied to aggregation functions must have a :format key")
        end

        it "should raise an exception if aggregate function is not a hash" do
          expect{
            @ddl.aggregate(:foo)
          }.to raise_error(DDLValidationError, "Functions supplied to aggregate should be a hash")
        end

        it "should raise an exception if function hash does not include a :args key" do
          expect{
            @ddl.stubs(:entities).returns({nil => {:action => :foo}})
            @ddl.aggregate({})
          }.to raise_error(DDLValidationError, "aggregate method for action 'foo' missing a function parameter")
        end

        it "should correctly add an aggregate function to the function array" do
          @ddl.stubs(:entities).returns({nil => {:aggregate => nil}})
          @ddl.aggregate({:function => :foo, :args => [:bar]})
          @ddl.entities.should == {nil => {:aggregate => [{:function => :foo, :args => [:bar]}]}}
        end
      end

      describe "#action" do
        it "should ensure a description is set" do
          expect {
            @ddl.action("act", {})
          }.to raise_error("Action needs a :description property")
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
          @ddl.action("act", :description => "rspec") { @ddl.instance_variable_get("@current_entity").should == "act" }
        end
      end
    end
  end
end
