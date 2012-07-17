#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe Agent do
      before do
        ddl = stub
        ddl.stubs(:meta).returns({})
        DDL.stubs(:new).returns(ddl)

        @agent = Agent.new
        @agent.reply = {}
        @agent.request = {}
      end

      describe "#meta" do
        it "should be deprecated" do
          Log.expects(:warn).with(regexp_matches(/setting meta data in agents have been deprecated/))
          Agent.metadata("foo")
        end
      end

      describe "#load_ddl" do
        it "should load the correct DDL" do
          ddl = stub
          ddl.stubs(:meta).returns({:timeout => 5})

          DDL.expects(:new).with("agent", :agent).returns(ddl)

          Agent.new.timeout.should == 5
        end

        it "should fail if the DDL isn't loaded" do
          DDL.expects(:new).raises("failed to load")
          Log.expects(:error).once
          expect { Agent.new }.to raise_error(DDLValidationError)
        end

        it "should default to 10 second timeout" do
          ddl = stub
          ddl.stubs(:meta).returns({})

          DDL.expects(:new).with("agent", :agent).returns(ddl)

          Agent.new.timeout.should == 10
        end
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

        it "should catch validation errors and turn them into use case specific ones" do
          @agent.request = {:input_key => "should be a number"}
          Validator.expects(:validate).raises(ValidatorError, "input_key should be a number")
          expect { @agent.send(:validate, :input_key, :number) }.to raise_error("Input input_key did not pass validation: input_key should be a number")
        end
      end
    end
  end
end
