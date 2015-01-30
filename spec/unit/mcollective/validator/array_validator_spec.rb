#!/usr/bin/env rspec
require 'spec_helper'
require 'mcollective/validator/array_validator'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if a given element is not defined in a given array" do
        expect{
          Validator::ArrayValidator.validate("element1",["element0", "element2"])
        }.to raise_error(ValidatorError, "value should be one of element0, element2")
      end

      it "should not raise an exception if a given element is defined in a given array" do
        Validator::ArrayValidator.validate("element1", ["element1", "element2"])
      end
    end
  end
end
