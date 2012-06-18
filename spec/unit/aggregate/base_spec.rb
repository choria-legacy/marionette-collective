#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  class Aggregate
    describe Base do
      describe "#initialize" do
        it "should set the correct instance variables and call the startup hook" do
          Base.any_instance.expects(:startup_hook).once
          base = Base.new("value", [], "%s%s", "rspec")
          base.name.should == "MCollective::Aggregate::Base"
          base.output_name.should == "value"
          base.aggregate_format.should == "%s%s"
          base.action.should == "rspec"
        end
      end

      describe "#startup_hook and #process_result" do
        it "should raise an exception for an unimplemented startup_hook method " do
          expect{
            base = Base.new("value", [], "", "rspec")
          }.to raise_error RuntimeError, "'startup_hook' method of function class MCollective::Aggregate::Base has not yet been implemented"
        end

        it "should raise an exception for an unimplemented process_result method" do
          Base.any_instance.stubs(:startup_hook)
          base = Base.new("value", [], "", "rspec")
          expect{
            base.process_result
          }.to raise_error RuntimeError,"'process_result' method of function class MCollective::Aggregate::Base has not yet been implemented"
        end
      end

      describe "summarize" do
        it "should raise and exception if the result type has not been set" do
          Base.any_instance.stubs(:startup_hook)
          base = Base.new("value", [], "", "rspec")
          expect{
            base.summarize
          }.to raise_error RuntimeError, "Result type is not set while trying to summarize aggregate function results"
        end

        it "should return the correct result class if result type has been set" do
          result_object = mock
          result_object.stubs(:new)

          Base.any_instance.stubs(:startup_hook)
          base = Base.new("value", [], "", "rspec")
          base.result[:type] = :result_type
          base.expects(:result_class).with(:result_type).returns(result_object)
          base.summarize
        end
      end
    end
  end
end
