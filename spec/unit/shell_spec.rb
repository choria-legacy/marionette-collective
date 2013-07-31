#!/usr/bin/env rspec

require 'spec_helper'
require 'pathname'

module MCollective
  describe Shell do
    describe "#initialize" do
      it "should set locale by default" do
        s = Shell.new("date")
        s.environment.should == {"LC_ALL" => "C"}
      end

      it "should merge environment and keep locale" do
        s = Shell.new("date", :environment => {"foo" => "bar"})
        s.environment.should == {"LC_ALL" => "C", "foo" => "bar"}
      end

      it "should allow locale to be overridden" do
        s = Shell.new("date", :environment => {"LC_ALL" => "TEST", "foo" => "bar"})
        s.environment.should == {"LC_ALL" => "TEST", "foo" => "bar"}
      end

      it "should set no environment when given nil" do
        s = Shell.new("date", :environment => nil)
        s.environment.should == {}
      end

      it "should save the command" do
        s = Shell.new("date")
        s.command.should == "date"
      end

      it "should check the cwd exist" do
        expect {
          s = Shell.new("date", :cwd => "/nonexistant")
        }.to raise_error("Directory /nonexistant does not exist")
      end

      it "should warn of illegal stdin" do
        expect {
          s = Shell.new("date", :stdin => nil)
        }.to raise_error("stdin should be a String")
      end

      it "should warn of illegal stdout" do
        expect {
          s = Shell.new("date", :stdout => nil)
        }.to raise_error("stdout should support <<")
      end

      it "should warn of illegal stderr" do
        expect {
          s = Shell.new("date", :stderr => nil)
        }.to raise_error("stderr should support <<")
      end

      it "should set stdout" do
        s = Shell.new("date", :stdout => "stdout")
        s.stdout.should == "stdout"
      end

      it "should set stderr" do
        s = Shell.new("date", :stderr => "stderr")
        s.stderr.should == "stderr"
      end

      it "should set stdin" do
        s = Shell.new("date", :stdin => "hello world")
        s.stdin.should == "hello world"
      end
    end

    describe "#runcommand" do
      let(:nl) do
        if MCollective::Util.windows? && STDOUT.tty? && STDERR.tty?
          "\r\n"
        else
          "\n"
        end
      end

      it "should run the command" do
        Shell.any_instance.stubs("systemu").returns(true).once.with("date", "stdout" => '', "stderr" => '', "env" => {"LC_ALL" => "C"}, 'cwd' => Dir.tmpdir)
        s = Shell.new("date")
        s.runcommand
      end

      it "should set stdin, stdout and status" do
        s = Shell.new('ruby -e "STDERR.puts \"stderr\"; STDOUT.puts \"stdout\""')
        s.runcommand
        s.stdout.should == "stdout#{nl}"
        s.stderr.should == "stderr#{nl}"
        s.status.exitstatus.should == 0
      end

      it "should report correct exitcode" do
        s = Shell.new('ruby -e "exit 1"')
        s.runcommand

        s.status.exitstatus.should == 1
      end

      it "should have correct environment" do
        s = Shell.new('ruby -e "puts ENV[\'LC_ALL\'];puts ENV[\'foo\'];"', :environment => {"foo" => "bar"})
        s.runcommand
        s.stdout.should == "C#{nl}bar#{nl}"
      end

      it "should save stdout in custom stdout variable" do
        out = "STDOUT"

        s = Shell.new('echo foo', :stdout => out)
        s.runcommand

        s.stdout.should == "STDOUTfoo#{nl}"
        out.should == "STDOUTfoo#{nl}"
      end

      it "should save stderr in custom stderr variable" do
        out = "STDERR"

        s = Shell.new('ruby -e "STDERR.puts \"foo\""', :stderr => out)
        s.runcommand

        s.stderr.should == "STDERRfoo#{nl}"
        out.should == "STDERRfoo#{nl}"
      end

      it "should run in the correct cwd" do
        tmpdir = Pathname.new(Dir.tmpdir).realpath.to_s
        s = Shell.new('ruby -e "puts Dir.pwd"', :cwd => tmpdir)

        s.runcommand

        s.stdout.should == "#{tmpdir}#{nl}"
      end

      it "should send the stdin" do
        s = Shell.new('ruby -e "puts STDIN.gets"', :stdin => "hello world")
        s.runcommand

        s.stdout.should == "hello world#{nl}"
      end

      it "should support multiple lines of stdin" do
        s = Shell.new('ruby -e "puts STDIN.gets;puts;puts STDIN.gets"', :stdin => "first line\n2nd line")
        s.runcommand

        s.stdout.should == "first line#{nl}#{nl}2nd line#{nl}"
      end

      it "should quietly catch Errno::ESRCH if the systemu process has completed" do
        s = Shell.new("echo foo")
        Thread.any_instance.stubs(:alive?).raises(Errno::ESRCH)
        s.runcommand
      end
    end
  end
end
