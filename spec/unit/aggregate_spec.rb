#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Aggregate do
    let(:ddl) do
      {
        :aggregate => [{:function => :func, :args=>[:foo, {:format => "%s"}]}],
        :action => "test_action",
        :output => {:foo => nil, :bar => nil}
      }
    end

    describe '#create_functions' do
      let(:function){mock}

      it "should load all the functions with a format if defined" do
        function.expects(:new).with(:foo, {}, "%s", 'test_action')
        Aggregate.any_instance.expects(:contains_output?).returns(true)
        Aggregate.any_instance.expects(:load_function).once.returns(function)
        Aggregate.new(ddl)
      end

      it "should load all the functions without a format if it isn't defined" do
        function.expects(:new).with(:foo, {}, nil, 'test_action')
        Aggregate.any_instance.expects(:load_function).once.returns(function)
        ddl[:aggregate].first[:args][1][:format] = nil
        Aggregate.new(ddl)
      end

      it "should not load invalid aggregate functions" do
        invalid_ddl = { :aggregate => [{:function => :func, :args=>[:foo], :format => "%s"}, {:function => :func, :args=>[:fail], :format => "%s"}],
                        :action => "test_action",
                        :output => {:foo => nil, :bar => nil}}

        function.stubs(:new).returns("function")
        Aggregate.any_instance.stubs(:load_function).returns(function)

        Log.expects(:error)
        @aggregate = Aggregate.new(invalid_ddl)
        @aggregate.functions.should == ["function"]
        @aggregate.failed.should == [:fail]
      end

      it "should pass aditional arguments if specified in the ddl" do
        function.expects(:new).with(:foo, {:extra => "extra"}, "%s", 'test_action')
        Aggregate.any_instance.expects(:load_function).once.returns(function)
        ddl[:aggregate].first[:args][1][:extra] = "extra"
        Aggregate.new(ddl)
      end
    end

    describe '#contains_ouput?' do
      before :all do
        Aggregate.any_instance.stubs(:create_functions)
        @aggregate = Aggregate.new(ddl)
      end

      it "should return false if the ddl output does not include the function's input" do
        result = @aggregate.contains_output?(:baz)
        result.should == false
      end

      it "should return true if the ddl output includes the function's input" do
        result = @aggregate.contains_output?(:foo)
        result.should == true
      end
    end

    describe '#call_functions' do
      let(:aggregate){ Aggregate.new(ddl)}
      let(:result){ RPC::Result.new("rspec", "rspec", :sender => "rspec", :statuscode => 0, :statusmsg => "rspec", :data => {:test => :result})}
      let(:function) {mock}

      before :each do
        Aggregate.any_instance.stubs(:create_functions)
      end

      it "should call all of the functions" do
        function.expects(:process_result).with(:result, result).once
        function.expects(:output_name).returns(:test)
        aggregate.functions = [function]

        aggregate.call_functions(result)
      end

      it "should not fail if 'process_result' method raises an exception" do
        aggregate.functions = [function]
        function.stubs(:output_name).returns(:test)
        function.stubs(:process_result).raises("Failed")

        Log.expects(:error)
        aggregate.call_functions(result)
      end

      it "should not fail if 'summarize' method raises en exception" do
        function.stubs(:summarize).raises("Failed")
        function.stubs(:output_name).returns("rspec")
        aggregate.functions = [function]

        Log.expects(:error)
        result = aggregate.summarize
      end
    end

    describe '#summarize' do
      it "should return the ordered function results" do
        Aggregate.any_instance.stubs(:create_functions)
        aggregate = Aggregate.new(ddl)

        func1 = mock
        func1.expects(:summarize).returns(func1)
        func1.stubs(:result).returns(:output => 5)

        func2 = mock
        func2.expects(:summarize).returns(func2)
        func2.stubs(:result).returns(:output => 2)

        aggregate.functions = [func1, func2]

        result = aggregate.summarize
        result.should == [func2, func1]
      end
    end

    describe '#load_function' do
      before :all do
        Aggregate.any_instance.stubs(:create_functions)
        @aggregate = Aggregate.new(ddl)
      end

      it "should return a class object if it can be loaded" do
        PluginManager.expects(:loadclass).with("MCollective::Aggregate::Test")
        Aggregate.expects(:const_get).with("Test")
        function = @aggregate.load_function("test")
      end

      it "should raise an exception if the class object cannot be loaded" do
        PluginManager.expects(:loadclass).with("MCollective::Aggregate::Test")
        expect {
          function = @aggregate.load_function("test")
        }.to raise_error("Aggregate function file 'test.rb' cannot be loaded")
      end
    end
  end
end
