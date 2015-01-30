#!/usr/bin/env rspec

require 'spec_helper'

require 'mcollective/discovery/stdin'

module MCollective
  class Discovery
    describe Stdin do
      describe "#discover" do
        before do
          @client = mock
          @client.stubs(:options).returns({})
          @client.stubs(:options).returns({:discovery_options => []})
          STDIN.stubs(:read).with().returns("one\ntwo\n")
        end

        it "should use a simple string list" do
          Stdin.discover(Util.empty_filter, 0, 0, @client).should == ["one", "two"]
        end

        ['auto', 'json', 'text', nil].each do |type|
          it "should fail if no data is given (type %{type})" do
            unless type.nil?
              @client.stubs(:options).returns({:discovery_options => [type]})
            end
            STDIN.stubs(:read).with().returns(" ")
            expect { Stdin.discover(Util.empty_filter, 0, 0, @client) }.to raise_error("data piped on STDIN contained only whitespace - could not discover hosts from it.")
          end
        end

        it "should work for JSON data" do
          STDIN.stubs(:read).with().returns('[{"sender":"example.com"},{"sender":"another.com"}]')
          Stdin.discover(Util.empty_filter, 0, 0, @client).should == ["example.com", "another.com"]
        end

        it "should regex filters" do
          Stdin.discover(Util.empty_filter.merge("identity" => [/one/]), 0, 0, @client).should == ["one"]
        end

        it "should filter against non regex nodes" do
          Stdin.discover(Util.empty_filter.merge("identity" => ["one"]), 0, 0, @client).should == ["one"]
        end

        it "should fail for invalid identities" do
          [" one", "two ", " three ", "four four"].each do |host|
            STDIN.stubs(:read).with().returns("#{host}\n")

            expect {
              Stdin.discover(Util.empty_filter, 0, 0, @client)
            }.to raise_error('Identities can only match /\w\.\-/')
          end
        end

        it "should raise on incorrect options" do
            @client.stubs(:options).returns({:discovery_options => ['foo']})
            expect {
              Stdin.discover(Util.empty_filter, 0, 0, @client)
            }.to raise_error('stdin discovery plugin only knows the types auto/text/json, not "foo"')
        end

      end
    end
  end
end
