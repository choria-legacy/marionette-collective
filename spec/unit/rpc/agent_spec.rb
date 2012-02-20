#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Agent do
      before do
        @agent = Agent.new
        @agent.reply = {}
        @agent.request = {}
      end

      describe "#run" do
        before do
          @status = mock
          @status.stubs(:exitstatus).returns(0)
          @shell = mock
          @shell.stubs(:runcommand)
          @shell.stubs(:status).returns(@status)
        end

        it "should accept stderr and stdout and force them to be strings" do
          Shell.expects(:new).with("rspec", {:stderr => "", :stdout => ""}).returns(@shell)
          @agent.send(:run, "rspec", {:stderr => :err, :stdout => :out})
          @agent.reply[:err].should == ""
          @agent.reply[:out].should == ""
        end

        it "should accept existing variables for stdout and stderr and fail if they dont support <<" do
          @agent.reply[:err] = "err"
          @agent.reply[:out] = "out"

          Shell.expects(:new).with("rspec", {:stderr => "err", :stdout => "out"}).returns(@shell)
          @agent.send(:run, "rspec", {:stderr => @agent.reply[:err], :stdout => @agent.reply[:out]})
          @agent.reply[:err].should == "err"
          @agent.reply[:out].should == "out"

          @agent.reply.expects("fail!").with("stderr should support << while calling run(rspec)").raises("stderr fail")
          expect { @agent.send(:run, "rspec", {:stderr => nil, :stdout => ""}) }.to raise_error("stderr fail")

          @agent.reply.expects("fail!").with("stdout should support << while calling run(rspec)").raises("stdout fail")
          expect { @agent.send(:run, "rspec", {:stderr => "", :stdout => nil}) }.to raise_error("stdout fail")
        end

        it "should set stdin, cwd and environment if supplied" do
          Shell.expects(:new).with("rspec", {:stdin => "stdin", :cwd => "cwd", :environment => "env"}).returns(@shell)
          @agent.send(:run, "rspec", {:stdin => "stdin", :cwd => "cwd", :environment => "env"})
        end

        it "should ignore unknown options" do
          Shell.expects(:new).with("rspec", {}).returns(@shell)
          @agent.send(:run, "rspec", {:rspec => "rspec"})
        end

        it "should chomp strings if configured to do so" do
          Shell.expects(:new).with("rspec", {:stderr => 'err', :stdout => 'out'}).returns(@shell)

          @agent.reply[:err] = "err"
          @agent.reply[:out] = "out"

          @agent.reply[:err].expects("chomp!")
          @agent.reply[:out].expects("chomp!")

          @agent.send(:run, "rspec", {:chomp => true, :stdout => @agent.reply[:out], :stderr => @agent.reply[:err]})
        end

        it "should return the exitstatus" do
          Shell.expects(:new).with("rspec", {}).returns(@shell)
          @agent.send(:run, "rspec", {}).should == 0
        end

        it "should handle nil from the shell handler" do
          @shell.expects(:status).returns(nil)
          Shell.expects(:new).with("rspec", {}).returns(@shell)
          @agent.send(:run, "rspec", {}).should == -1
        end
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

        it "should correctly validate list data" do
          @agent.request = {:str => "foo"}
          expect { @agent.send(:validate, :str, ["bar", "baz"]) }.to raise_error(InvalidRPCData, /str should be one of bar, baz/)

          @agent.request = {:str => "foo"}
          expect { @agent.send(:validate, :str, ["bar", "baz", "foo"]) }
          @agent.send(:validate, :str, ["bar", "baz", "foo"])
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
