#!/usr/bin/env rspec
require 'spec_helper'
require 'mcollective/validator/ipv6address_validator'

module MCollective
  module Validator
    describe "#validate" do
      it "should raise an exception if the supplied value is not an ipv6 address" do
        expect{
          Ipv6addressValidator.validate("foobar")
        }.to raise_error(ValidatorError, "value should be an ipv6 address")
      end

      it "should not raise an exception if the supplied value is an ipv6 address" do
        Ipv6addressValidator.validate("2001:db8:85a3:8d3:1319:8a2e:370:7348")
      end
    end
  end
end
