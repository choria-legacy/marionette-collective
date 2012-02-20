#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Helpers do
      describe "#extract_hosts_from_json" do
        it "should fail for non array data" do
          expect {
            Helpers.extract_hosts_from_json("{}")
          }.to raise_error "JSON hosts list is not an array"
        end

        it "should fail for non hash array members" do
          senders = [{"sender" => "sender1"}, {"sender" => "sender3"}, ""].to_json

          expect {
            Helpers.extract_hosts_from_json(senders)
          }.to raise_error "JSON host list is not an array of Hashes"
        end

        it "should fail for hashes without senders" do
          senders = [{"sender" => "sender1"}, {"sender" => "sender3"}, {}].to_json

          expect {
            Helpers.extract_hosts_from_json(senders)
          }.to raise_error "JSON host list does not have senders in it"
        end

        it "should return all found unique senders" do
          senders = [{"sender" => "sender1"}, {"sender" => "sender3"}, {"sender" => "sender1"}].to_json

          Helpers.extract_hosts_from_json(senders).should == ["sender1", "sender3"]
        end
      end

      describe "#extract_hosts_from_array" do
        it "should support single string lists" do
          Helpers.extract_hosts_from_array("foo").should == ["foo"]
        end

        it "should support arrays" do
          Helpers.extract_hosts_from_array(["foo", "bar"]).should == ["foo", "bar"]
        end

        it "should fail for non string array members" do
          expect {
            Helpers.extract_hosts_from_array(["foo", 1])
          }.to raise_error("1 should be a string")
        end
      end
    end
  end
end
