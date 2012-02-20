#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe ActionRunner do
      before(:each) do
        @req = mock
        @req.expects(:agent).returns("spectester")
        @req.expects(:action).returns("tester")

        @runner = ActionRunner.new("/bin/echo 1", @req, :json)
      end

      describe "#initialize" do
        it "should set command" do
          @runner.command.should == "/bin/echo 1"
        end

        it "should set agent" do
          @runner.agent.should == "spectester"
        end

        it "should set action" do
          @runner.action.should == "tester"
        end

        it "should set format" do
          @runner.format.should == :json
        end

        it "should set request" do
          @runner.request.should == @req
        end

        it "should set stdout" do
          @runner.stdout.should == ""
        end

        it "should set stderr" do
          @runner.stderr.should == ""
        end
      end

      describe "#shell" do
        it "should create a shell instance with correct settings" do
          s = @runner.shell("test", "infile", "outfile")

          s.command.should == "test infile outfile"
          s.cwd.should == Dir.tmpdir
          s.stdout.should == ""
          s.stderr.should == ""
          s.environment["MCOLLECTIVE_REQUEST_FILE"].should == "infile"
          s.environment["MCOLLECTIVE_REPLY_FILE"].should == "outfile"
        end
      end

      describe "#load_results" do
        it "should call the correct format loader" do
          req = mock
          req.expects(:agent).returns("spectester")
          req.expects(:action).returns("tester")

          runner = ActionRunner.new("/bin/echo 1", req, :foo)
          runner.expects("load_foo_results").returns({:foo => :bar})
          runner.load_results("/dev/null").should == {:foo => :bar}
        end

        it "should set all keys to Symbol" do
          data = {"foo" => "bar", "bar" => "baz"}
          Tempfile.open("mcollective_test", Dir.tmpdir) do |f|
            f.puts data.to_json
            f.close

            results = @runner.load_results(f.path)
            results.should == {:foo => "bar", :bar => "baz"}
          end
        end
      end

      describe "#load_json_results" do
        it "should load data from a file" do
          Tempfile.open("mcollective_test", Dir.tmpdir) do |f|
            f.puts '{"foo":"bar","bar":"baz"}'
            f.close

            @runner.load_json_results(f.path).should == {"foo" => "bar", "bar" => "baz"}
          end

        end

        it "should return empty data on JSON parse error" do
          @runner.load_json_results("/dev/null").should == {}
        end

        it "should return empty data for missing files" do
          @runner.load_json_results("/nonexisting").should == {}
        end

        it "should load complex data correctly" do
          data = {"foo" => "bar", "bar" => {"one" => "two"}}
          Tempfile.open("mcollective_test", Dir.tmpdir) do |f|
            f.puts data.to_json
            f.close

            @runner.load_json_results(f.path).should == data
          end
        end

      end

      describe "#saverequest" do
        it "should call the correct format serializer" do
          req = mock
          req.expects(:agent).returns("spectester")
          req.expects(:action).returns("tester")

          runner = ActionRunner.new("/bin/echo 1", req, :foo)

          runner.expects("save_foo_request").with(req).returns('{"foo":"bar"}')

          runner.saverequest(req)
        end

        it "should save to a temp file" do
          @req.expects(:to_json).returns({:foo => "bar"}.to_json)
          fname = @runner.saverequest(@req).path

          JSON.load(File.read(fname)).should == {"foo" => "bar"}
          File.dirname(fname).should == Dir.tmpdir
        end
      end

      describe "#save_json_request" do
        it "should return correct json data" do
          @req.expects(:to_json).returns({:foo => "bar"}.to_json)
          @runner.save_json_request(@req).should == '{"foo":"bar"}'
        end
      end

      describe "#canrun?" do
        it "should correctly report executables" do
          if Util.windows?
            @runner.canrun?(File.join(ENV['SystemRoot'], "explorer.exe")).should == true
          else
            @runner.canrun?("/bin/true").should == true
          end
        end

        it "should detect missing files" do
          @runner.canrun?("/nonexisting").should == false
        end
      end

      describe "#to_s" do
        it "should return correct data" do
          @runner.to_s.should == "spectester#tester command: /bin/echo 1"
        end
      end

      describe "#tempfile" do
        it "should return a TempFile" do
          @runner.tempfile("foo").class.should == Tempfile
        end

        it "should contain the prefix in its name" do
          @runner.tempfile("foo").path.should match(/foo/)
        end
      end
    end
  end
end
