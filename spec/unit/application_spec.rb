#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

module MCollective
    describe Application do
        before do
            Application.intialize_application_options
            @argv_backup = ARGV.clone
        end

        describe "#application_options" do
            it "should return the application options" do
                Application.application_options.should == {:description  => nil,
                                                           :usage        => [],
                                                           :cli_arguments => []}
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
                Application.intialize_application_options.should == {:description  => nil,
                                                                     :usage        => [],
                                                                     :cli_arguments => []}
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

        describe "#main" do
            it "should detect applications without a #main" do
                IO.any_instance.expects(:puts).with("Applications need to supply a 'main' method")

                expect {
                    Application.new.run
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
    end
end
