#!/usr/bin/env rspec

require 'spec_helper'
require 'mcollective/security/aes_security'

module MCollective
  module Security
    # Clear the PluginManager so that security plugin tests do not conflict
    PluginManager.clear
    describe Aes_security do
      let(:pluginconf) do
        {"aes.client_cert_dir" => "testing"}
      end

      let(:config) do
        conf = mock
        conf.stubs(:identity).returns("test")
        conf.stubs(:configured).returns(true)
        conf.stubs(:pluginconf).returns(pluginconf)
        conf
      end

      let(:plugin) do
        Aes_security.new
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
          expect(plugin.deserialize(Marshal.dump(unsafe_payload))).to eq(unsafe_payload)
          expect(plugin.deserialize(Marshal.dump(safe_payload))).to eq(safe_payload)
        end

        context "yaml" do
          before do
            pluginconf['aes.serializer'] = 'yaml'
          end

          if YAML.respond_to? :safe_load
            it "should round-trip yaml with symbols" do
              expect(plugin.deserialize(YAML.dump(safe_payload))).to eq(safe_payload)
            end

            it "should reject yaml with other objects" do
              expect{ plugin.deserialize(YAML.dump(unsafe_payload)) }.to raise_error(Psych::DisallowedClass)
            end
          else
            it "should raise on older Ruby" do
              expect{ plugin.deserialize(YAML.dump(safe_payload)) }.to raise_error("YAML.safe_load not supported by Ruby #{RUBY_VERSION}. Please update to Ruby 2.1+.")
            end
          end
        end
      end

      describe "#decodemsg" do
        let(:body) do
        {:sslpubkey => "ssl_public_key",
         :callerid  => "cert=testing",
         :requestid => 1}
        end

        before :each do
          pluginconf["aes.learn_pubkeys"] = "1"
          plugin.stubs(:should_process_msg?)
          plugin.stubs(:deserialize).returns(body)
          plugin.stubs(:decrypt)
          plugin.stubs(:deserialize).returns(body)
          plugin.stubs(:update_secure_property)
        end

        it "should not learn the public key if the key has not been passed" do
          body.delete(:sslpubkey)
          plugin.decodemsg(msg)
          File.expects(:exist?).never
          File.expects(:open).never
        end

        it "should not learn the public key if keyfile is present on disk" do
          File.expects(:exist?).with("testing/testing.pem").returns(true)
          File.expects(:open).never
          plugin.decodemsg(msg)
        end

        it "should not learn the key if there is no ca_cert and insecure_learning is false" do
          File.expects(:exist?).returns(false)
          Log.expects(:warn).with() do |msg|
            msg =~ /No CA certificate specified/
          end
          expect {
            plugin.decodemsg(msg)
          }.to raise_error SecurityValidationFailed
        end

        it "should not learn the key if the cert cannot be verified against the CA" do
          File.expects(:exist?).returns(false)
          pluginconf["aes.ca_cert"] = "ca_cert"
          plugin.expects(:validate_certificate).with("ssl_public_key", "testing").returns(false)
          Log.expects(:warn).with() do |msg|
            msg.should match(/Unable to validate certificate/)
          end
          expect {
            plugin.decodemsg(msg)
          }.to raise_error SecurityValidationFailed
        end

        it "it should learn the public key if insecure_learning is enabled" do
          pluginconf["aes.insecure_learning"] = "1"
          File.expects(:exist?).returns(false)
          Log.expects(:warn).with() do |msg|
            msg.should match(/Do NOT use this mode in sensitive environments/)
          end
          File.expects(:open)
          plugin.decodemsg(msg)
        end

        it "should learn the public key if the CA can verify the cert" do
          File.expects(:exist?).returns(false)
          pluginconf["aes.ca_cert"] = "ca_cert"
          File.expects(:read).with("testing/testing.pem").returns("ssl_public_key")
          plugin.expects(:validate_certificate).with("ssl_public_key", "testing").twice.returns(true)
          File.expects(:open)
          plugin.decodemsg(msg)
        end
      end

      describe "#validate_certificate" do
        let(:cert) do
          mock
        end

        let(:ca_cert) do
          ca = mock
          ca.stubs(:add_file).returns(true)
          ca
        end

        let(:callerid) do
          "rspec_caller"
        end

        it "should fail if the cert is not a X509 certificate" do
          OpenSSL::X509::Certificate.expects(:new).with("ssl_cert").raises(OpenSSL::X509::CertificateError)
          Log.expects(:warn).with() do |msg|
            msg.should match(/Received public key that is not a X509 certficate/)
          end
          plugin.validate_certificate("ssl_cert", callerid).should be_false
        end

        it "should fail if the name in the cert doesn't match the callerid" do
          OpenSSL::X509::Certificate.expects(:new).with("ssl_cert").returns(cert)
          plugin.stubs(:certname_from_certificate).with(cert).returns("not_rspec_caller")
          Log.expects(:warn).with() do |msg|
            msg.should match(/certname 'rspec_caller' doesn't match certificate 'not_rspec_caller'/)
          end
          plugin.validate_certificate("ssl_cert", callerid).should be_false
        end

        it "should fail if the cert wasn't signed by the CA" do
          OpenSSL::X509::Certificate.expects(:new).with("ssl_cert").returns(cert)
          plugin.stubs(:certname_from_certificate).with(cert).returns("rspec_caller")
          OpenSSL::X509::Store.stubs(:new).returns(ca_cert)
          ca_cert.stubs(:verify).with(cert).returns(false)
          Log.expects(:warn).with() do |msg|
            msg.should match(/Unable to validate certificate/)
          end
          plugin.validate_certificate("ssl_cert", callerid).should be_false
        end

        it "should validate the cert" do
          OpenSSL::X509::Certificate.expects(:new).with("ssl_cert").returns(cert)
          plugin.stubs(:certname_from_certificate).with(cert).returns("rspec_caller")
          OpenSSL::X509::Store.stubs(:new).returns(ca_cert)
          ca_cert.stubs(:verify).with(cert).returns(true)
          plugin.validate_certificate("ssl_cert", callerid).should be_true
        end
      end
    end
  end
end
