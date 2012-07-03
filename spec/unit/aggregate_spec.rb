#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Aggregate do
    let(:ddl) do
      {
        :aggregate => [{:function => :func, :args=>[:value], :format => "%s"}],
        :action => "test_action",
        :output => {:foo => nil, :bar => nil}
      }
    end

    describe '#create_functions' do
      before :each do
        Aggregate.any_instance.stubs(:contains_output?)
      end

      it "should load all the functions with a format if defined" do
        function = mock
        function.expects(:new).with(:value, [], "%s", 'test_action')
        Aggregate.any_instance.expects(:load_function).once.returns(function)
        @aggregate = Aggregate.new(ddl)
      end

      it "should load all the functions without a format if it isn't defined" do
        function = mock
        function.expects(:new).with(:value, [], nil, 'test_action')
        Aggregate.any_instance.expects(:load_function).once.returns(function)
        ddl[:aggregate].first[:format] = nil
        @aggregate = Aggregate.new(ddl)
      end
    end

    describe '#contains_ouput?' do
      before :all do
        Aggregate.any_instance.stubs(:create_functions)
        @aggregate = Aggregate.new(ddl)
      end

      it "should raise an exception if the ddl output does not include the function's input" do
        expect{
          @aggregate.contains_output?(:baz)
        }.to raise_error "'test_action' action does not contain output 'baz'"
      end

      it "should not raise an exception if the ddl output includes the function's input" do
        @aggregate.contains_output?(:foo)
      end
    end

    describe '#call_functions' do
      it "should call all of the functions" do
        Aggregate.any_instance.stubs(:create_functions)
        aggregate = Aggregate.new(ddl)

        function = mock
        function.expects(:process_result).with(:result, {:data => {:test => :result}}).once
        function.expects(:output_name).returns(:test)
        aggregate.functions = [function]
        aggregate.call_functions({:data => {:test => :result}})
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
        }.to raise_error "Aggregate function file 'test.rb' cannot be loaded"
      end
    end
  end
end
