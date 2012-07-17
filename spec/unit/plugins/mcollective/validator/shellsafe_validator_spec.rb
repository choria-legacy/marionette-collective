#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/validator/shellsafe_validator.rb'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if the given string is not shellsafe" do
        ['`', '$', ';', '|', '&&', '>', '<'].each do |chr|
          expect{
            ShellsafeValidator.validate("#{chr}test")
          }.to raise_error ValidatorError, "value should not have #{chr} in it"
        end
      end

      it "should not raise an exception if the given string is shellsafe" do
        ShellsafeValidator.validate("test")
      end
    end
  end
end
