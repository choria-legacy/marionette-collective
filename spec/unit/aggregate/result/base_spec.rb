#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  class Aggregate
    module Result
      describe Base do
        describe "#initialize" do
          it "should raise an exception if neither the ddl or the aggregate function defines a format" do
            expect{
              base = Base.new(:structure, nil, :action)
            }.to raise_error RuntimeError, "No aggregate_format defined in ddl or aggregate function"
          end
        end

        describe "#to_s" do
          it "should raise an exception if the to_s method isn't implemented" do
            base = Base.new(:structure, :aggregate_format, :action)
            expect{
              base.to_s
            }.to raise_error RuntimeError, "'to_s' method not implemented for result class 'MCollective::Aggregate::Result::Base'"
          end
        end
      end
    end
  end
end
