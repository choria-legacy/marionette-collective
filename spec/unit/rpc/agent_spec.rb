#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

module MCollective
  module RPC
    describe Agent do
      before do
        @agent = Agent.new
      end

      describe "#validate" do
        it "should detect missing data" do
          @agent.request = {}
          expect { @agent.send(:validate, :foo, String) }.to raise_error(MissingRPCData, "please supply a foo argument")
        end

        it "should support regular expressions" do
          @agent.request = {:foo => "this is a test, 123"}

          expect { @agent.send(:validate, :foo, /foo/) }.to raise_error(InvalidRPCData, /foo should match/)
          @agent.send(:validate, :foo, /is a test, \d\d\d$/)
        end

        it "should support type checking" do
          @agent.request = {:str => "foo"}

          expect { @agent.send(:validate, :str, Numeric) }.to raise_error(InvalidRPCData, /str should be a Numeric/)
          @agent.send(:validate, :str, String)
        end

        it "should correctly validate ipv4 addresses" do
          @agent.request = {:goodip4 => "1.1.1.1",
            :badip4  => "300.300.300.300"}

          expect { @agent.send(:validate, :badip4, :ipv4address) }.to raise_error(InvalidRPCData, /badip4 should be an ipv4 address/)
          @agent.send(:validate, :goodip4, :ipv4address)
        end

        it "should correctly validate ipv6 addresses" do
          @agent.request = {:goodip6 => "2a00:1450:8006::93",
            :badip6  => "300.300.300.300"}

          expect { @agent.send(:validate, :badip6, :ipv6address) }.to raise_error(InvalidRPCData, /badip6 should be an ipv6 address/)
          @agent.send(:validate, :goodip6, :ipv6address)
        end

        it "should correctly validate boolean data" do
          @agent.request = {:true => true, :false => false, :string => "foo", :number => 1}

          @agent.send(:validate, :true, :boolean)
          @agent.send(:validate, :false, :boolean)
          expect { @agent.send(:validate, :string, :boolean) }.to raise_error(InvalidRPCData)
          expect { @agent.send(:validate, :number, :boolean) }.to raise_error(InvalidRPCData)
        end

        it "should correctly identify characters that are not shell safe" do
          @agent.request = {:backtick => 'foo`bar',
            :semicolon => 'foo;bar',
            :dollar => 'foo$(bar)',
            :pipe => 'foo|bar',
            :redirto => 'foo>bar',
            :inputfrom => 'foo<bar',
            :good => 'foo bar baz'}

          expect { @agent.send(:validate, :backtick, :shellsafe) }.to raise_error(InvalidRPCData, /backtick should not have ` in it/)
          expect { @agent.send(:validate, :semicolon, :shellsafe) }.to raise_error(InvalidRPCData, /semicolon should not have ; in it/)
          expect { @agent.send(:validate, :dollar, :shellsafe) }.to raise_error(InvalidRPCData, /dollar should not have \$ in it/)
          expect { @agent.send(:validate, :pipe, :shellsafe) }.to raise_error(InvalidRPCData, /pipe should not have \| in it/)
          expect { @agent.send(:validate, :redirto, :shellsafe) }.to raise_error(InvalidRPCData, /redirto should not have > in it/)
          expect { @agent.send(:validate, :inputfrom, :shellsafe) }.to raise_error(InvalidRPCData, /inputfrom should not have \< in it/)

          @agent.send(:validate, :good, :shellsafe)
        end
      end
    end
  end
end
