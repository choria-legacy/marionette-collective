#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/validator/ipv4address_validator.rb'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if the supplied value is not an ipv4 address" do
        expect{
          Ipv4addressValidator.validate("foobar")
        }.to raise_error(ValidatorError, "value should be an ipv4 address")
      end

      it "should not raise an exception if the supplied value is an ipv4 address" do
        Ipv4addressValidator.validate("1.2.3.4")
      end
    end
  end
end
