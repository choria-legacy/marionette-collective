#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/validator/any_validator.rb'

module MCollective
  module Validator
    describe "#validate" do
      it "should accept anything" do
        ["1", 1, :one, Time.now].each do |data|
          Validator::AnyValidator.validate(data)
        end
      end
    end
  end
end
