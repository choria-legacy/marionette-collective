#!/usr/bin/env rspec
require 'spec_helper'
require 'mcollective/validator/typecheck_validator'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if the given value is not of the supplied type" do
        [[1, String], ['test', :integer], ['test', :float], ['test', :number], [1, :string], ['test', :boolean]].each do |val|
          expect{
            TypecheckValidator.validate(*val)
          }.to raise_error(ValidatorError, "value should be a #{val[1].to_s}")
        end
      end

      it "should not raise an exception if the given value is of the supplied type" do
        [["test", String], [1, :integer], [1.2, :float], [1, :number], ["test", :string], [true, :boolean]].each do |val|
          TypecheckValidator.validate(*val)
        end
      end
    end
  end
end
