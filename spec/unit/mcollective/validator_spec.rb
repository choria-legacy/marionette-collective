#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/validator/array_validator'

module MCollective
  module Validator
    describe "#load_validators" do
      it "should not reload the plugins if the plugin cache has not expired" do
        Validator.instance_variable_set(:@last_load, nil)
        PluginManager.expects(:find_and_load).with("validator").once
        Validator.load_validators
        Validator.load_validators
      end
    end

    describe "#[]" do
      before do
        Validator.load_validators
      end

      it "should return the correct class if klass is given as klass" do
        result = Validator["array"]
        result.should == ArrayValidator
      end
      it "should return the correct class if klass is given as KlassValidator" do
        result = Validator["ArrayValidator"]
        result.should == ArrayValidator
      end
      it "should return the correct class if klass is given as :klass" do
        result = Validator[:array]
        result.should == ArrayValidator
      end
    end

    describe "#method_missing" do
      it "should load a plugin if a validator method is called and the plugin exists" do
        ArrayValidator.expects(:validate).with(2, [1,2,3])
        result = Validator.array(2,[1,2,3])
      end

      it "should call super if a validator method is called and the plugin does not exist" do
        expect{
          Validator.rspec(1,2,3)
        }.to raise_error(ValidatorError)
      end
    end

    describe "#validator_class" do
      it "should return the correct string for a given validator plugin name" do
        result = Validator.validator_class("test")
        result.should == "TestValidator"
      end
    end

    describe "#has_validator?" do
      it "should return true if the validator has been loaded" do
        Validator.const_set(:TestValidator, Class)
        Validator.has_validator?("test").should == true
      end

      it "should return false if the validator has not been loaded" do
        Validator.has_validator?("test2").should == false
      end
    end
  end
end
