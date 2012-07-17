#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/validator/length_validator.rb'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if the given string's length is greater than the given value" do
        expect{
          LengthValidator.validate("test", 3)
        }.to raise_error ValidatorError, "Input string is longer than 3 character(s)"
      end

      it "should not raise an exception if the given string's length is less than the given value" do
        LengthValidator.validate("test", 4)
      end
    end
  end
end
