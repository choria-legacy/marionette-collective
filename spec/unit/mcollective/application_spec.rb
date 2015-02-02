#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Application do
    before do
      Application.intialize_application_options
      @argv_backup = ARGV.clone
    end

    describe "#application_options" do
      it "should return the application options" do
        Application.application_options.should == {:description          => nil,
                                                   :usage                => [],
                                                   :cli_arguments        => [],
                                                   :exclude_arg_sections => []}
      end
    end

    describe "#[]=" do
      it "should set the application option" do
        Application["foo"] = "bar"
        Application.application_options["foo"].should == "bar"
      end
    end

    describe "#[]" do
      it "should set the application option" do
        Application[:cli_arguments].should == []
      end
    end

    describe "#intialize_application_options" do
      it "should initialize application options correctly" do
        Application.intialize_application_options.should == {:description          => nil,
                                                             :usage                => [],
                                                             :cli_arguments        => [],
                                                             :exclude_arg_sections => []}
      end
    end

    describe "#description" do
      it "should set the description correctly" do
        Application.description "meh"
        Application[:description].should == "meh"
      end
    end

    describe "#usage" do
      it "should set the usage correctly" do
        Application.usage "meh"
        Application.usage "foo"

        Application[:usage].should == ["meh", "foo"]
      end
    end

    describe "#exclude_argument_sections" do
      it "should set the excluded sections correctly" do
        Application.exclude_argument_sections "common", "rpc", "filter"
        Application[:exclude_arg_sections].should == ["common", "rpc", "filter"]
        Application.exclude_argument_sections ["common", "rpc", "filter"]
        Application[:exclude_arg_sections].should == ["common", "rpc", "filter"]
      end

      it "should detect unknown sections" do
        expect { Application.exclude_argument_sections "rspec" }.to raise_error("Unknown CLI argument section rspec")
      end
    end

    describe "#option" do
      it "should add an option correctly" do
        Application.option :test,
                           :description => "description",
                           :arguments => "--config CONFIG",
                           :type => Integer,
                           :required => true

        args = Application[:cli_arguments].first
        args.delete(:validate)

        args.should == {:name=>:test,
                        :arguments=>"--config CONFIG",
                        :required=>true,
                        :type=>Integer,
                        :description=>"description"}
      end

      it "should set correct defaults" do
        Application.option :test, {}

        args = Application[:cli_arguments].first
        args.delete(:validate)

        args.should == {:name=>:test,
                        :arguments=>[],
                        :required=>false,
                        :type=>String,
                        :description=>nil}
      end
    end

    describe "#validate_option" do
      it "should pass validations" do
        a = Application.new
        a.validate_option(Proc.new {|v| v == 1}, "key", 1)
      end

      it "should print an error to STDERR on error" do
        IO.any_instance.expects(:puts).with("Validation of key failed: failed").at_least_once
        Application.any_instance.stubs("exit").returns(true)

        a = Application.new
        a.validate_option(Proc.new {|v| "failed"}, "key", 1)
      end

      it "should exit on valdation error" do
        IO.any_instance.expects(:puts).at_least_once
        Application.any_instance.stubs("exit").returns(true)

        a = Application.new
        a.validate_option(Proc.new {|v| "failed"}, "key", 1)
      end
    end

    describe "#application_parse_options" do
      it "should pass the requested help value to the clioptions method" do
        ARGV.clear

        app = Application.new
        app.expects(:clioptions).with(true)
        app.application_parse_options(true)

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should support creating arrays of values" do
        Application.any_instance.stubs("main").returns(true)

        Application.option :foo,
                           :description => "meh",
                           :arguments => "--foo [FOO]",
                           :type => :array

        ARGV.clear
        ARGV << "--foo=bar" << "--foo=baz"

        a = Application.new
        a.run
        a.configuration.should == {:foo=>["bar", "baz"]}

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should support boolean options" do
        Application.any_instance.stubs("main").returns(true)

        Application.option :foo,
                           :description => "meh",
                           :arguments => "--foo",
                           :type => :boolean

        ARGV.clear
        ARGV << "--foo"

        a = Application.new
        a.run
        a.configuration.should == {:foo=>true}

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should support unsetting boolean options" do
        Application.any_instance.stubs("main").returns(true)

        Application.option :foo,
                           :description => "meh",
                           :arguments => "--[no-]foo",
                           :type => :boolean

        ARGV.clear
        ARGV << "--no-foo"

        a = Application.new
        a.run
        a.configuration.should == {:foo=>false}

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should set the application description as head" do
        OptionParser.any_instance.stubs(:define_head).with("meh")

        ARGV.clear

        Application.description "meh"
        Application.new.application_parse_options

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should set the application usage as a banner" do
        OptionParser.any_instance.stubs(:banner).with("meh")

        ARGV.clear

        Application.usage "meh"
        Application.new.application_parse_options

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should support validation" do
        IO.any_instance.expects(:puts).with("Validation of foo failed: failed").at_least_once
        Application.any_instance.stubs("exit").returns(true)
        Application.any_instance.stubs("main").returns(true)

        Application.option :foo,
                           :description => "meh",
                           :required => true,
                           :default => "meh",
                           :arguments => "--foo [FOO]",
                           :validate => Proc.new {|v| "failed"}

        ARGV.clear
        ARGV << "--foo=bar"

        a = Application.new
        a.run

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should support default values" do
        Application.any_instance.stubs("main").returns(true)

        Application.option :foo,
                           :description => "meh",
                           :required => true,
                           :default => "meh",
                           :arguments => "--foo [FOO]"

        a = Application.new
        a.run
        a.configuration.should == {:foo => "meh"}
      end

      it "should enforce required options" do
        Application.any_instance.stubs("exit").returns(true)
        Application.any_instance.stubs("main").returns(true)
        OptionParser.any_instance.stubs("parse!").returns(true)
        IO.any_instance.expects(:puts).with(anything).at_least_once
        IO.any_instance.expects(:puts).with("The foo option is mandatory").at_least_once

        ARGV.clear
        ARGV << "--foo=bar"

        Application.option :foo,
                           :description => "meh",
                           :required => true,
                           :arguments => "--foo [FOO]"

        Application.new.run

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should call post_option_parser" do
        OptionParser.any_instance.stubs("parse!").returns(true)
        Application.any_instance.stubs("post_option_parser").returns(true).at_least_once
        Application.any_instance.stubs("main").returns(true)

        ARGV.clear
        ARGV << "--foo=bar"

        Application.option :foo,
                           :description => "meh",
                           :arguments => "--foo [FOO]"

        Application.new.run

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end

      it "should create an application option" do
        OptionParser.any_instance.stubs("parse!").returns(true)
        OptionParser.any_instance.expects(:on).with(anything, anything, anything, anything).at_least_once
        OptionParser.any_instance.expects(:on).with('--foo [FOO]', String, 'meh').at_least_once
        Application.any_instance.stubs("main").returns(true)

        ARGV.clear
        ARGV << "--foo=bar"

        Application.option :foo,
                           :description => "meh",
                           :arguments => "--foo [FOO]"

        Application.new.run

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end
    end

    describe "#initialize" do
      it "should parse the command line options at application run" do
        Application.any_instance.expects("application_parse_options").once
        Application.any_instance.stubs("main").returns(true)

        Application.new.run
      end
    end

    describe "#application_options" do
      it "sshould return the application options" do
        Application.new.application_options.should == Application.application_options
      end
    end

    describe "#application_description" do
      it "should provide the right description" do
        Application.description "Foo"
        Application.new.application_description.should == "Foo"
      end
    end

    describe "#application_usage" do
      it "should provide the right usage" do
        Application.usage "Foo"
        Application.new.application_usage.should == ["Foo"]
      end
    end

    describe "#application_cli_arguments" do
      it "should provide the right usage" do
        Application.option :foo,
                           :description => "meh",
                           :arguments => "--foo [FOO]"

        args = Application.new.application_cli_arguments.first

        # need to remove this cos we cant validate procs for equality afaik
        args.delete(:validate)

        args.should == {:description=>"meh",
                        :name=>:foo,
                        :arguments=>"--foo [FOO]",
                        :type=>String,
                        :required=>false}
      end
    end

    describe "#help" do
      it "should generate help using the full user supplied options" do
        app = Application.new
        app.expects(:clioptions).with(true).once
        app.help
      end
    end

    describe "#main" do
      it "should detect applications without a #main" do
        IO.any_instance.expects(:puts).with("Applications need to supply a 'main' method")

        expect {
          Application.new.run
        }.to raise_error(SystemExit)
      end

      it "should raise SystemExit exceptions for exit events" do
        connector = mock
        connector.expects(:disconnect)
        PluginManager.expects("[]").with("connector_plugin").returns(connector)

        a = Application.new
        a.expects(:main).raises(SystemExit)

        expect {
          a.run
        }.to raise_error(SystemExit)
      end
    end

    describe "#configuration" do
      it "should return the correct configuration" do
        Application.any_instance.stubs("main").returns(true)

        ARGV.clear
        ARGV << "--foo=bar"

        Application.option :foo,
                           :description => "meh",
                           :arguments => "--foo [FOO]"

        a = Application.new
        a.run

        a.configuration.should == {:foo => "bar"}

        ARGV.clear
        @argv_backup.each{|a| ARGV << a}
      end
    end

    describe "#halt" do
      before do
        @stats = {:discoverytime => 0, :discovered => 0, :failcount => 0, :responses => 0, :okcount => 0}
      end

      it "should exit with code 0 if discovery was done and all responses passed" do
        app = Application.new

        @stats[:discoverytime] = 2
        @stats[:discovered] = 2
        @stats[:responses] = 2
        @stats[:okcount] = 2

        app.halt_code(@stats).should == 0
      end

      it "should exit with code 0 if no discovery were done but responses were received" do
        app = Application.new

        @stats[:responses] = 1
        @stats[:okcount] = 1
        @stats[:discovered] = 1

        app.halt_code(@stats).should == 0
      end

      it "should exit with code 1 if discovery info is missing" do
        app = Application.new

        app.halt_code({}).should == 1
      end

      it "should exit with code 1 if no nodes were discovered and discovery was done" do
        app = Application.new

        @stats[:discoverytime] = 2

        app.halt_code(@stats).should == 1
      end

      it "should exit with code 2 if a request failed for some nodes" do
        app = Application.new

        @stats[:discovered] = 2
        @stats[:failcount] = 1
        @stats[:discoverytime] = 2
        @stats[:responses] = 2

        app.halt_code(@stats).should == 2
      end

      it "should exit with code 2 when no discovery were done and there were failure results" do
        app = Application.new

        @stats[:discovered] = 1
        @stats[:failcount] = 1
        @stats[:discoverytime] = 0
        @stats[:responses] = 1

        app.halt_code(@stats).should == 2
      end

      it "should exit with code 3 if no responses were received after discovery" do
        app = Application.new

        @stats[:discovered] = 1
        @stats[:discoverytime] = 2

        app.halt_code(@stats).should == 3
      end

      it "should exit with code 4 if no discovery was done and no responses were received" do
        app = Application.new

        app.halt_code(@stats).should == 4
      end
    end

    describe "#disconnect" do
      it "should disconnect from the connector plugin" do
        connector = mock
        connector.expects(:disconnect)
        PluginManager.expects("[]").with("connector_plugin").returns(connector)

        Application.new.disconnect
      end
    end

    describe "#clioptions" do
      it "should pass the excluded argument section" do
        oparser = mock
        oparser.stubs(:parse)

        Application.exclude_argument_sections "rpc"

        Optionparser.expects(:new).with({:verbose => false, :progress_bar => true}, "filter", ["rpc"]).returns(oparser)

        Application.new.clioptions(false)
      end

      it "should add the RPC options" do
        oparser = mock
        oparser.stubs(:parse).yields(oparser, {})
        oparser.stubs(:banner=)
        oparser.stubs(:define_tail)

        Optionparser.stubs(:new).with({:verbose => false, :progress_bar => true}, "filter", []).returns(oparser)
        RPC::Helpers.expects(:add_simplerpc_options).with(oparser, {})

        Application.new.clioptions(false)
      end

      it "should support bypassing the RPC options" do
        oparser = mock
        oparser.stubs(:parse).yields(oparser, {})
        oparser.stubs(:banner=)
        oparser.stubs(:define_tail)

        Application.exclude_argument_sections "rpc"

        Optionparser.stubs(:new).with({:verbose => false, :progress_bar => true}, "filter", ["rpc"]).returns(oparser)
        RPC::Helpers.expects(:add_simplerpc_options).never

        Application.new.clioptions(false)
      end

      it "should return the help text if requested" do
        parser = mock
        parser.expects(:help)

        oparser = mock
        oparser.stubs(:parse).yields(oparser, {})
        oparser.stubs(:banner=)
        oparser.stubs(:define_tail)
        oparser.expects(:parser).returns(parser)

        Optionparser.stubs(:new).with({:verbose => false, :progress_bar => true}, "filter", []).returns(oparser)
        RPC::Helpers.expects(:add_simplerpc_options).with(oparser, {})

        Application.new.clioptions(true)
      end
    end

    describe "#application_failure" do
      before do
        @app = Application.new
      end

      it "on SystemExit it should disconnect and exit without backtraces or error messages" do
        @app.expects(:disconnect)
        expect { @app.application_failure(SystemExit.new) }.to raise_error(SystemExit)
      end

      it "should print a single line error message" do
        out = StringIO.new
        @app.stubs(:disconnect)
        @app.stubs(:exit).with(1)
        @app.stubs(:options).returns({})

        Config.instance.stubs(:color).returns(false)
        e = mock
        e.stubs(:backtrace).returns([])
        e.stubs(:to_s).returns("rspec")

        out.expects(:puts).with(regexp_matches(/rspec application failed to run/))

        @app.application_failure(e, out)
      end

      it "should print a backtrace if options are unset or verbose is enabled" do
        out = StringIO.new
        @app.stubs(:disconnect)
        @app.stubs(:exit).with(1)
        @app.stubs(:options).returns(nil)

        Config.instance.stubs(:color).returns(false)
        e = mock
        e.stubs(:backtrace).returns(["rspec"])
        e.stubs(:to_s).returns("rspec")

        @app.expects(:options).returns({:verbose => true}).times(3)
        out.expects(:puts).with(regexp_matches(/ application failed to run/))
        out.expects(:puts).with(regexp_matches(/from rspec  <---/))
        out.expects(:puts).with(regexp_matches(/rspec.+Mocha::Mock/))

        @app.application_failure(e, out)
      end
    end

    describe "#run" do
      before do
        @app = Application.new
      end

      it "should parse the application options, run main and disconnect" do
        @app.expects(:application_parse_options)
        @app.expects(:main)
        @app.expects(:disconnect)

        @app.run
      end

      it "should allow the application plugin to validate configuration variables" do
        @app.expects("respond_to?").with(:validate_configuration).returns(true)
        @app.expects(:validate_configuration).once

        @app.stubs(:application_parse_options)
        @app.stubs(:main)
        @app.stubs(:disconnect)

        @app.run
      end

      it "should start the sleeper thread on windows" do
        Util.expects("windows?").returns(true)
        Util.expects(:setup_windows_sleeper).once

        @app.stubs(:application_parse_options)
        @app.stubs(:main)
        @app.stubs(:disconnect)

        @app.run
      end

      it "should catch handle exit() correctly" do
        @app.expects(:main).raises(SystemExit)
        @app.expects(:disconnect).once

        expect { @app.run }.to raise_error(SystemExit)
      end

      it "should catch all exceptions and process them correctly" do
        @app.expects(:main).raises("rspec")
        @app.expects(:application_failure).once
        @app.run
      end
    end
  end
end
