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

        ["/one#{File::PATH_SEPARATOR}/two", "/three"].each do |path|
          File.expects(:readlines).with("/nonexisting").returns(["libdir = #{path}"])

          Config.instance.loadconfig("/nonexisting")

          PluginManager.clear
        end

        File.expects(:readlines).with("/nonexisting").returns(["libdir = four"])

        expect { Config.instance.loadconfig("/nonexisting") }.to raise_error(/should be absolute paths/)
      end

      it 'should prepend $libdir to $LOAD_PATH' do
        Util.expects(:absolute_path?).with('/test').returns(true)

        File.stubs(:exists?).with("/nonexisting").returns(true)

        File.expects(:readlines).with('/nonexisting').returns(['libdir = /test'])

        Config.instance.loadconfig("/nonexisting")

        $LOAD_PATH[0].should == '/test'
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
          File.expects(:readlines).with("/nonexisting").returns(["identity = #{input}", "libdir=/nonexistinglib"])
          File.expects(:exists?).with("/nonexisting").returns(true)

          expect {
            Config.instance.loadconfig("/nonexisting")
          }.to raise_error('Identities can only match /\w\.\-/')
        end
      end

      it "should strip whitespaces from config keys" do
        File.expects(:exists?).with("/nonexisting").returns(true)
        File.expects(:readlines).with("/nonexisting").returns([" identity= your.example.com  ", "libdir=/nonexisting"])

        config = Config.instance
        config.loadconfig("/nonexisting")
        config.identity.should == "your.example.com"
      end

      it "should allow valid identities" do
        ["foo", "foo_bar", "foo-bar", "foo-bar-123", "foo.bar", "foo_bar_123"].each do |input|
          File.expects(:readlines).with("/nonexisting").returns(["identity = #{input}", "libdir=/nonexistinglib"])
          File.expects(:exists?).with("/nonexisting").returns(true)
          PluginManager.stubs(:loadclass)
          PluginManager.stubs("<<")

          Config.instance.loadconfig("/nonexisting")
        end
      end

      it "should set direct_addressing to true by default" do
        File.expects(:readlines).with("/nonexisting").returns(["libdir=/nonexistinglib"])
        File.expects(:exists?).with("/nonexisting").returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        Config.instance.loadconfig("/nonexisting")
        Config.instance.direct_addressing.should == true
      end

      it "should allow direct_addressing to be disabled in the config file" do
        File.expects(:readlines).with("/nonexisting").returns(["libdir=/nonexistinglib", "direct_addressing=n"])
        File.expects(:exists?).with("/nonexisting").returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        Config.instance.loadconfig("/nonexisting")
        Config.instance.direct_addressing.should == false
      end

      it "should not allow the syslog logger type on windows" do
        Util.expects("windows?").returns(true).twice
        File.expects(:readlines).with("/nonexisting").returns(["libdir=/nonexistinglib", "logger_type=syslog"])
        File.expects(:exists?).with("/nonexisting").returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        expect { Config.instance.loadconfig("/nonexisting") }.to raise_error("The sylog logger is not usable on the Windows platform")
      end

      it "should support multiple default_discovery_options" do
        File.expects(:readlines).with("/nonexisting").returns(["default_discovery_options = 1", "default_discovery_options = 2", "libdir=/nonexistinglib"])
        File.expects(:exists?).with("/nonexisting").returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        Config.instance.loadconfig("/nonexisting")
        Config.instance.default_discovery_options.should == ["1", "2"]
      end

      it "should not allow non integer values when expecting an integer value" do
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        ["registerinterval", "max_log_size", "direct_addressing_threshold", "publish_timeout",
         "fact_cache_time", "ttl"].each do |key|
          File.expects(:readlines).with("/nonexisting").returns(["#{key} = nan"])
          File.expects(:exists?).with("/nonexisting").returns(true)

          expect{
            Config.instance.loadconfig("/nonexisting")
          }.to raise_error "Could not parse value for configuration option '#{key}' with value 'nan'"
         end
      end

      it 'should log a warning when using a deprecated option' do
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        ["topicprefix", "topicsep", "queueprefix", "rpchelptemplate", "helptemplatedir"].each do |key|
          File.expects(:exists?).with("/nonexisting").returns(true)
          File.expects(:readlines).with("/nonexisting").returns(["#{key} = nan", "libdir = /nonexistinglib"])

          Log.stubs(:warn)
          Log.expects(:warn).with("Use of deprecated '#{key}' option.  This option is ignored and should be removed from '/nonexisting'")
          Config.instance.loadconfig("/nonexisting")
        end
      end

      it 'should enable agents by default' do
        File.expects(:readlines).with("/nonexisting").returns(["libdir=/nonexistinglib"])
        File.expects(:exists?).with("/nonexisting").returns(true)
        PluginManager.stubs(:loadclass)
        PluginManager.stubs("<<")

        Config.instance.loadconfig("/nonexisting")
        Config.instance.activate_agents.should == true
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

      it "should strip whitespaces from config keys" do
        Dir.expects(:new).with(@plugindir).returns(["foo.cfg"])
        File.expects(:open).with(File.join(@plugindir, "foo.cfg"), "r").returns(["   rspec  = test"])
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
        File.expects(:readlines).with(servercfg).returns(["plugin.rspec.key = default", "libdir=/nonexisting"])
        File.stubs(:directory?).with("/nonexisting").returns(true)

        Dir.expects(:new).with(@plugindir).returns(["rspec.cfg"])
        File.expects(:open).with(File.join(@plugindir, "rspec.cfg"), "r").returns(["key = overridden"])

        Config.instance.loadconfig(servercfg)
        Config.instance.pluginconf.should == {"rspec.key" => "overridden"}
      end
    end
  end
end
