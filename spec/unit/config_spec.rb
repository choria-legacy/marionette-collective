#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Config do
    describe "#loadconfig" do
      it "should only test that libdirs are absolute paths" do
        Util.expects(:absolute_path?).with("/one").returns(true)
        Util.expects(:absolute_path?).with("/two").returns(true)
        Util.expects(:absolute_path?).with("/three").returns(true)
        Util.expects(:absolute_path?).with("four").returns(false)

        File.stubs(:exists?).with("/nonexisting").returns(true)
        File.stubs(:exists?).with(File.join(File.dirname("/nonexisting"), "rpc-help.erb")).returns(true)

        ["/one:/two", "/three"].each do |path|
          File.stubs(:open).with("/nonexisting", "r").returns(StringIO.new("libdir = #{path}"))

          Config.instance.loadconfig("/nonexisting")

          PluginManager.clear
        end

        File.stubs(:open).with("/nonexisting", "r").returns(StringIO.new("libdir = four"))

        expect { Config.instance.loadconfig("/nonexisting") }.to raise_error(/should be absolute paths/)
      end

      it "should not allow any path like construct for identities" do
        # Taken from puppet test cases
        ['../foo', '..\\foo', './../foo', '.\\..\\foo',
          '/foo', '//foo', '\\foo', '\\\\goo',
          "test\0/../bar", "test\0\\..\\bar",
          "..\\/bar", "/tmp/bar", "/tmp\\bar", "tmp\\bar",
          " / bar", " /../ bar", " \\..\\ bar",
          "c:\\foo", "c:/foo", "\\\\?\\UNC\\bar", "\\\\foo\\bar",
          "\\\\?\\c:\\foo", "//?/UNC/bar", "//foo/bar",
          "//?/c:/foo"
        ].each do |input|
          File.expects(:open).with("/nonexisting", "r").returns(StringIO.new("identity = #{input}"))
          File.expects(:exists?).with("/nonexisting").returns(true)
          File.expects(:exists?).with(File.join(File.dirname("/nonexisting"), "rpc-help.erb")).returns(true)

          expect {
            Config.instance.loadconfig("/nonexisting")
          }.to raise_error('Identities can only match /\w\.\-/')
        end
      end

      it "should allow valid identities" do
        ["foo", "foo_bar", "foo-bar", "foo-bar-123", "foo.bar", "foo_bar_123"].each do |input|
          File.expects(:open).with("/nonexisting", "r").returns(StringIO.new("identity = #{input}"))
          File.expects(:exists?).with("/nonexisting").returns(true)
          File.expects(:exists?).with(File.join(File.dirname("/nonexisting"), "rpc-help.erb")).returns(true)
          PluginManager.stubs(:loadclass)
          PluginManager.stubs("<<")

          Config.instance.loadconfig("/nonexisting")
        end
      end

      it "should not allow the syslog logger type on windows" do
        Util.expects("windows?").returns(true).twice
        File.expects(:open).with("/nonexisting", "r").returns(StringIO.new("logger_type = syslog"))
        File.expects(:exists?).with("/nonexisting").returns(true)
        File.expects(:exists?).with(File.join(File.dirname("/nonexisting"), "rpc-help.erb")).returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        expect { Config.instance.loadconfig("/nonexisting") }.to raise_error("The sylog logger is not usable on the Windows platform")
      end

      it "should default to finding the help template in the same dir as the config file" do
        path = File.join(File.dirname("/nonexisting"), "rpc-help.erb")

        File.expects(:open).with("/nonexisting", "r").returns(StringIO.new(""))
        File.expects(:exists?).with("/nonexisting").returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        File.expects(:exists?).with(path).returns(true)

        Config.instance.loadconfig("/nonexisting")
        Config.instance.rpchelptemplate.should == path
      end

      it "should fall back to old behavior if the help template file does not exist in the config dir" do
        path = File.join(File.dirname("/nonexisting"), "rpc-help.erb")

        File.expects(:open).with("/nonexisting", "r").returns(StringIO.new(""))
        File.expects(:exists?).with("/nonexisting").returns(true)
        File.expects(:exists?).with(path).returns(false)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        Config.instance.loadconfig("/nonexisting")
        Config.instance.rpchelptemplate.should == "/etc/mcollective/rpc-help.erb"
      end

      it "should support multiple default_discovery_options" do
        File.expects(:open).with("/nonexisting", "r").returns(StringIO.new("default_discovery_options = 1\ndefault_discovery_options = 2"))
        File.expects(:exists?).with("/nonexisting").returns(true)
        File.expects(:exists?).with(File.join(File.dirname("/nonexisting"), "rpc-help.erb")).returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        Config.instance.loadconfig("/nonexisting")
        Config.instance.default_discovery_options.should == ["1", "2"]
      end
    end

    describe "#read_plugin_config_dir" do
      before do
        @plugindir = File.join("/", "nonexisting", "plugin.d")

        File.stubs(:directory?).with(@plugindir).returns(true)

        Config.instance.set_config_defaults("")
      end

      it "should not fail if the supplied directory is missing" do
        File.expects(:directory?).with(@plugindir).returns(false)
        Config.instance.read_plugin_config_dir(@plugindir)
        Config.instance.pluginconf.should == {}
      end

      it "should skip files that do not match the expected filename pattern" do
        Dir.expects(:new).with(@plugindir).returns(["foo.txt"])

        IO.expects(:open).with(File.join(@plugindir, "foo.txt")).never

        Config.instance.read_plugin_config_dir(@plugindir)
      end

      it "should load the config files" do
        Dir.expects(:new).with(@plugindir).returns(["foo.cfg"])
        File.expects(:open).with(File.join(@plugindir, "foo.cfg"), "r").returns([]).once
        Config.instance.read_plugin_config_dir(@plugindir)
      end

      it "should set config parameters correctly" do
        Dir.expects(:new).with(@plugindir).returns(["foo.cfg"])
        File.expects(:open).with(File.join(@plugindir, "foo.cfg"), "r").returns(["rspec = test"])
        Config.instance.read_plugin_config_dir(@plugindir)
        Config.instance.pluginconf.should == {"foo.rspec" => "test"}
      end

      it "should override main config file" do
        configfile = File.join(@plugindir, "foo.cfg")
        servercfg = File.join(File.dirname(@plugindir), "server.cfg")

        PluginManager.stubs(:loadclass)

        File.stubs(:exists?).returns(true)
        File.stubs(:directory?).with(@plugindir).returns(true)
        File.stubs(:exists?).with(servercfg).returns(true)
        File.expects(:open).with(servercfg, "r").returns(["plugin.rspec.key = default"])

        Dir.expects(:new).with(@plugindir).returns(["rspec.cfg"])
        File.expects(:open).with(File.join(@plugindir, "rspec.cfg"), "r").returns(["key = overridden"])

        Config.instance.loadconfig(servercfg)
        Config.instance.pluginconf.should == {"rspec.key" => "overridden"}
      end
    end
  end
end
