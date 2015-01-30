#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module RPC
    describe ActionRunner do
      before(:each) do
        @req = mock
        @req.stubs(:agent).returns("spectester")
        @req.stubs(:action).returns("tester")

        command = "/bin/echo 1"

        @runner = ActionRunner.new(command, @req, :json)
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

        it "should set the command via path_to_command" do
          ActionRunner.any_instance.expects(:path_to_command).with("rspec").once
          ActionRunner.new("rspec", @req, :json)
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
            true_exe = ENV["PATH"].split(File::PATH_SEPARATOR).map {|f| p = File.join(f, "true") ;p if File.exists?(p)}.compact.first
            @runner.canrun?(true_exe).should == true
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

      describe "#path_to_command" do
        it "should return the command if it starts with separator" do
          command = "#{File::SEPARATOR}rspec"

          runner = ActionRunner.new(command , @req, :json)
          runner.path_to_command(command).should == command
        end

        it "should find the first match in the libdir" do
          Config.instance.expects(:libdir).returns(["#{File::SEPARATOR}libdir1", "#{File::SEPARATOR}libdir2"])

          action_in_first_dir = File.join(File::SEPARATOR, "libdir1", "agent", "spectester", "action.sh")
          action_in_first_dir_new = File.join(File::SEPARATOR, "libdir1", "mcollective", "agent", "spectester", "action.sh")
          action_in_last_dir = File.join(File::SEPARATOR, "libdir2", "agent", "spectester", "action.sh")
          action_in_last_dir_new = File.join(File::SEPARATOR, "libdir2", "mcollective", "agent", "spectester", "action.sh")

          File.expects("exists?").with(action_in_first_dir).returns(true)
          File.expects("exists?").with(action_in_first_dir_new).returns(false)
          File.expects("exists?").with(action_in_last_dir).never
          File.expects("exists?").with(action_in_last_dir_new).never
          ActionRunner.new("action.sh", @req, :json).command.should == action_in_first_dir
        end

        it "should find the match in the last libdir" do
          Config.instance.expects(:libdir).returns(["#{File::SEPARATOR}libdir1", "#{File::SEPARATOR}libdir2"])

          action_in_first_dir = File.join(File::SEPARATOR, "libdir1", "agent", "spectester", "action.sh")
          action_in_first_dir_new = File.join(File::SEPARATOR, "libdir1", "mcollective", "agent", "spectester", "action.sh")
          action_in_last_dir = File.join(File::SEPARATOR, "libdir2", "agent", "spectester", "action.sh")
          action_in_last_dir_new = File.join(File::SEPARATOR, "libdir2", "mcollective", "agent", "spectester", "action.sh")

          File.expects("exists?").with(action_in_first_dir).returns(false)
          File.expects("exists?").with(action_in_first_dir_new).returns(false)
          File.expects("exists?").with(action_in_last_dir).returns(true)
          File.expects("exists?").with(action_in_last_dir_new).returns(false)
          ActionRunner.new("action.sh", @req, :json).command.should == action_in_last_dir
        end

        it "should find the match in the 'new' directory layout" do
          Config.instance.expects(:libdir).returns(["#{File::SEPARATOR}libdir1", "#{File::SEPARATOR}libdir2"])

          action_in_new_dir = File.join(File::SEPARATOR, "libdir1", "mcollective", "agent", "spectester", "action.sh")
          action_in_old_dir = File.join(File::SEPARATOR, "libdir1", "agent", "spectester", "action.sh")

          File.expects("exists?").with(action_in_new_dir).returns(true)
          File.expects("exists?").with(action_in_old_dir).returns(false)
          ActionRunner.new("action.sh", @req, :json).command.should == action_in_new_dir
        end

        it "if the script is both the old and new locations, the new location should be preferred" do
          Config.instance.expects(:libdir).returns(["#{File::SEPARATOR}libdir1", "#{File::SEPARATOR}libdir2"])

          action_in_new_dir = File.join(File::SEPARATOR, "libdir1", "mcollective", "agent", "spectester", "action.sh")
          action_in_old_dir = File.join(File::SEPARATOR, "libdir1", "agent", "spectester", "action.sh")

          File.expects("exists?").with(action_in_new_dir).returns(true)
          File.expects("exists?").with(action_in_old_dir).returns(true)

          ActionRunner.new("action.sh", @req, :json).command.should == action_in_new_dir
        end
      end
    end
  end
end
