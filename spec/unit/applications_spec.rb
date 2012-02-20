#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Applications do
    before do
      tmpfile = Tempfile.new("mc_applications_spec")
      path = tmpfile.path
      tmpfile.close!

      @tmpdir = FileUtils.mkdir_p(path)
      @tmpdir = @tmpdir[0] if @tmpdir.is_a?(Array) # ruby 1.9.2
      $LOAD_PATH << @tmpdir

      @appsdir = File.join([@tmpdir, "mcollective", "application"])
      FileUtils.mkdir_p(@appsdir)

      FileUtils.cp(File.join([File.dirname(__FILE__), "..", "fixtures", "application", "test.rb"]), @appsdir)
    end

    after do
      FileUtils.rm_r(@tmpdir)
    end

    describe "[]" do
      it "should load the config" do
        Applications.expects(:load_config).once
        PluginManager.expects("[]").once
        Applications["test"]
      end

      it "should return the correct stored application" do
        app = mock("app")
        app.stubs(:run)

        Applications.expects(:load_config).once
        PluginManager.expects("[]").with("test_application").once.returns(app)
        Applications["test"].should == app
      end
    end

    describe "#run" do
      it "should load the configuration" do
        app = mock("app")
        app.stubs(:run)

        Applications.expects(:load_config).once
        Applications.expects(:load_application).once
        PluginManager.expects("[]").once.returns(app)

        Applications.run("test")
      end

      it "should load the application" do
        app = mock("app")
        app.stubs(:run)

        Applications.expects(:load_config).once
        Applications.expects(:load_application).with("test").once
        PluginManager.expects("[]").once.returns(app)

        Applications.run("test")
      end

      it "should invoke the application run method" do
        app = mock("app")
        app.stubs(:run).returns("hello world")

        Applications.expects(:load_config).once
        Applications.expects(:load_application)
        PluginManager.expects("[]").once.returns(app)

        Applications.run("test").should == "hello world"
      end
    end

    describe "#load_application" do
      it "should return the existing application if already loaded" do
        app = mock("app")
        app.stubs(:run)

        PluginManager << {:type => "test_application", :class => app}

        Applications.expects("load_config").never

        Applications.load_application("test")
      end

      it "should load the config" do
        Applications.expects("load_config").returns(true).once
        Applications.load_application("test")
      end

      it "should load the correct class from disk" do
        PluginManager.expects("loadclass").with("MCollective::Application::Test")
        Applications.expects("load_config").returns(true).once

        Applications.load_application("test")
      end

      it "should add the class to the plugin manager" do
        Applications.expects("load_config").returns(true).once

        PluginManager.expects("<<").with({:type => "test_application", :class => "MCollective::Application::Test"})

        Applications.load_application("test")
      end
    end

    describe "#list" do
      it "should load the configuration" do
        Applications.expects("load_config").returns(true).once
        Config.any_instance.expects("libdir").returns([@tmpdir])
        Applications.list
      end

      it "should add found applications to the list" do
        Applications.expects("load_config").returns(true).once
        Config.any_instance.expects("libdir").returns([@tmpdir])

        Applications.list.should == ["test"]
      end

      it "should print a friendly error and exit on failure" do
        Applications.expects("load_config").raises(Exception)
        IO.any_instance.expects(:puts).with(regexp_matches(/Failed to generate application list/)).once

        expect {
          Applications.list.should
        }.to raise_error(SystemExit)
      end
    end

    describe "#filter_extra_options" do
      it "should parse --config=x" do
        ["--config=x --foo=bar -f -f bar", "--foo=bar --config=x -f -f bar"].each do |t|
          Applications.filter_extra_options(t).should == "--config=x"
        end
      end

      it "should parse --config x" do
        ["--config x --foo=bar -f -f bar", "--foo=bar --config x -f -f bar"].each do |t|
          Applications.filter_extra_options(t).should == "--config=x"
        end
      end

      it "should parse -c x" do
        ["-c x --foo=bar -f -f bar", "--foo=bar -c x -f -f bar"].each do |t|
          Applications.filter_extra_options(t).should == "--config=x"
        end
      end
    end
  end
end
