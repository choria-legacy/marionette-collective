#!/usr/bin/env rspec
require 'spec_helper'
require 'mcollective/validator/regex_validator'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if the given string does not matches the given regular expression" do
        expect{
          RegexValidator.validate("test", "nottest")
        }.to raise_error(ValidatorError, "value should match nottest")
      end

      it "should not raise an exception if the given string's length is less than the given value" do
        RegexValidator.validate("test", "test")
      end
    end
  end
end
