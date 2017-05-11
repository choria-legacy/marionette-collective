#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/security/ssl'

module MCollective
  module Security
    # Clear the PluginManager so that security plugin tests do not conflict
    PluginManager.clear
    describe Ssl do
      let(:pluginconf) do
        {"ssl_server_public" => "server-public.pem",
         "ssl_client_private" => "client-private.pem",
         "ssl_client_public" => "client_public.pem"}
      end

      let(:config) do
        conf = mock
        conf.stubs(:identity).returns("test")
        conf.stubs(:configured).returns(true)
        conf.stubs(:pluginconf).returns(pluginconf)
        conf
      end

      let(:plugin) do
        Ssl.new
      end

      let(:msg) do
        m = mock
        m.stubs(:payload)
        m
      end

      before :each do
        stats = mock("stats")
        MCollective::PluginManager << {:type => "global_stats", :class => stats}
        MCollective::Config.stubs("instance").returns(config)
        MCollective::Log.stubs(:debug)
        MCollective::Log.stubs(:warn)
      end

      describe "#deserialize" do
        let(:safe_payload) {
          {:payload => "words", :ttl => 15}
        }

        class Sock
          attr_reader :size
          def initialize size
            @size = size
          end

          def ==(another_sock)
            self.size == another_sock.size
          end
        end

        let(:unsafe_payload) {
          {:payload => Sock.new(10)}
        }

        it "should accept marshal by default" do
          expect(plugin.send(:deserialize, Marshal.dump(unsafe_payload))).to eq(unsafe_payload)
          expect(plugin.send(:deserialize, Marshal.dump(safe_payload))).to eq(safe_payload)
        end

        context "yaml" do
          before do
            pluginconf['ssl_serializer'] = 'yaml'
          end

          if YAML.respond_to? :safe_load
            it "should round-trip yaml with symbols" do
              expect(plugin.send(:deserialize, YAML.dump(safe_payload))).to eq(safe_payload)
            end

            it "should reject yaml with other objects" do
              expect{ plugin.send(:deserialize, YAML.dump(unsafe_payload)) }.to raise_error(Psych::DisallowedClass)
            end
          else
            it "should raise on older Ruby" do
              expect{ plugin.send(:deserialize, YAML.dump(safe_payload)) }.to raise_error("YAML.safe_load not supported by Ruby #{RUBY_VERSION}. Please update to Ruby 2.1+.")
            end
          end
        end
      end
    end
  end
end
