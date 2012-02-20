#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Agents do
    before do
      tmpfile = Tempfile.new("mc_agents_spec")
      path = tmpfile.path
      tmpfile.close!

      @tmpdir = FileUtils.mkdir_p(path)
      @tmpdir = @tmpdir[0] if @tmpdir.is_a?(Array) # ruby 1.9.2

      @agentsdir = File.join([@tmpdir, "mcollective", "agent"])
      FileUtils.mkdir_p(@agentsdir)

      logger = mock
      logger.stubs(:log)
      logger.stubs(:start)
      Log.configure(logger)
    end

    after do
      FileUtils.rm_r(@tmpdir)
    end

    describe "#initialize" do
      it "should fail if configuration has not been loaded" do
        Config.any_instance.expects(:configured).returns(false)

        expect {
          Agents.new
        }.to raise_error("Configuration has not been loaded, can't load agents")
      end

      it "should load agents" do
        Config.any_instance.expects(:configured).returns(true)
        Agents.any_instance.expects(:loadagents).once

        Agents.new
      end
    end

    describe "#clear!" do
      it "should delete and unsubscribe all loaded agents" do
        Config.any_instance.expects(:configured).returns(true).at_least_once
        Config.any_instance.expects(:libdir).returns([@tmpdir])
        PluginManager.expects(:delete).with("foo_agent").once
        Util.expects(:make_subscriptions).with("foo", :broadcast).returns("foo_target")
        Util.expects(:unsubscribe).with("foo_target")

        a = Agents.new({"foo" => 1})
      end
    end

    describe "#loadagents" do
      before do
        Config.any_instance.stubs(:configured).returns(true)
        Config.any_instance.stubs(:libdir).returns([@tmpdir])
        Agents.any_instance.stubs("clear!").returns(true)
      end

      it "should delete all existing agents" do
        Agents.any_instance.expects("clear!").once
        a = Agents.new
      end

      it "should attempt to load agents from all libdirs" do
        Config.any_instance.expects(:libdir).returns(["/nonexisting", "/nonexisting"])
        File.expects("directory?").with("/nonexisting/mcollective/agent").twice

        a = Agents.new
      end

      it "should load found agents" do
        Agents.any_instance.expects("loadagent").with("test").once

        FileUtils.touch(File.join([@agentsdir, "test.rb"]))

        a = Agents.new
      end

      it "should load each agent unless already loaded" do
        Agents.any_instance.expects("loadagent").with("test").never

        FileUtils.touch(File.join([@agentsdir, "test.rb"]))

        PluginManager << {:type => "test_agent", :class => String.new}
        a = Agents.new
      end
    end

    describe "#loadagent" do
      before do
        FileUtils.touch(File.join([@agentsdir, "test.rb"]))
        Config.any_instance.stubs(:configured).returns(true)
        Config.any_instance.stubs(:libdir).returns([@tmpdir])
        Agents.any_instance.stubs("clear!").returns(true)
        PluginManager.stubs(:loadclass).returns(true)
        Util.stubs(:make_subscriptions).with("test", :broadcast).returns([{:agent => "test", :type => :broadcast, :collective => "test"}])
        Util.stubs(:subscribe).with([{:agent => "test", :type => :broadcast, :collective => "test"}]).returns(true)
        Agents.stubs(:findagentfile).returns(File.join([@agentsdir, "test.rb"]))
        Agents.any_instance.stubs("activate_agent?").returns(true)

        @a = Agents.new
      end

      it "should return false if the agent file is missing" do
        Agents.any_instance.expects(:findagentfile).returns(false).once
        @a.loadagent("test").should == false
      end

      it "should delete the agent before loading again" do
        PluginManager.expects(:delete).with("test_agent").twice
        @a.loadagent("test")
      end

      it "should load the agent class from disk" do
        PluginManager.expects(:loadclass).with("MCollective::Agent::Test")
        @a.loadagent("test")
      end

      it "should check if the agent should be activated" do
        Agents.any_instance.expects(:findagentfile).with("test").returns(File.join([@agentsdir, "test.rb"]))
        Agents.any_instance.expects("activate_agent?").with("test").returns(true)
        @a.loadagent("test").should == true
      end

      it "should set discovery and registration to be single instance plugins" do
        PluginManager.expects("<<").with({:type => "registration_agent", :class => "MCollective::Agent::Registration", :single_instance => true}).once
        PluginManager.expects("<<").with({:type => "discovery_agent", :class => "MCollective::Agent::Discovery", :single_instance => true}).once
        Agents.any_instance.expects("activate_agent?").with("registration").returns(true)
        Agents.any_instance.expects("activate_agent?").with("discovery").returns(true)

        PluginManager.expects(:loadclass).with("MCollective::Agent::Registration").returns(true).once
        PluginManager.expects(:loadclass).with("MCollective::Agent::Discovery").returns(true).once

        FileUtils.touch(File.join([@agentsdir, "registration.rb"]))
        FileUtils.touch(File.join([@agentsdir, "discovery.rb"]))

        @a.loadagent("registration")
        @a.loadagent("discovery")
      end

      it "should add general plugins as multiple instance plugins" do
        PluginManager.expects("<<").with({:type => "test_agent", :class => "MCollective::Agent::Test", :single_instance => false}).once
        @a.loadagent("test")
      end

      it "should add the agent to the plugin manager and subscribe" do
        PluginManager.expects("<<").with({:type => "foo_agent", :class => "MCollective::Agent::Foo", :single_instance => false})
        Util.stubs(:make_subscriptions).with("foo", :broadcast).returns([{:agent => "foo", :type => :broadcast, :collective => "test"}])
        Util.expects("subscribe").with([{:type => :broadcast, :agent => 'foo', :collective => 'test'}]).returns(true)
        Agents.any_instance.expects(:findagentfile).with("foo").returns(File.join([@agentsdir, "foo.rb"]))

        FileUtils.touch(File.join([@agentsdir, "foo.rb"]))

        @a.loadagent("foo")
      end

      it "should add the agent to the agent list" do
        Agents.agentlist.should == ["test"]
      end

      it "should return true on success" do
        @a.loadagent("test").should == true
      end

      it "should handle load exceptions" do
        Agents.any_instance.expects(:findagentfile).with("foo").returns(File.join([@agentsdir, "foo.rb"]))
        Log.expects(:error).with(regexp_matches(/Loading agent foo failed/))
        @a.loadagent("foo").should == false
      end

      it "should delete plugins that failed to load" do
        Agents.any_instance.expects(:findagentfile).with("foo").returns(File.join([@agentsdir, "foo.rb"]))
        PluginManager.expects(:delete).with("foo_agent").twice

        @a.loadagent("foo").should == false
      end
    end

    describe "#class_for_agent" do
      it "should return the correct class" do
        Config.any_instance.stubs(:configured).returns(true)
        Agents.any_instance.stubs(:loadagents).returns(true)
        Agents.new.class_for_agent("foo").should == "MCollective::Agent::Foo"
      end
    end

    describe "#activate_agent?" do
      before do
        Config.any_instance.stubs(:configured).returns(true)
        Agents.any_instance.stubs(:loadagents).returns(true)
        @a = Agents.new

        module MCollective::Agent;end
        class MCollective::Agent::Test; end
      end

      it "should check if the correct class has an activation method" do
        Agent::Test.expects("respond_to?").with("activate?").once

        @a.activate_agent?("test")
      end

      it "should call the activation method" do
        Agent::Test.expects("activate?").returns(true).once
        @a.activate_agent?("test")
      end

      it "should log a debug message and return true if the class has no activation method" do
        Agent::Test.expects("respond_to?").with("activate?").returns(false).once
        Log.expects(:debug).with("MCollective::Agent::Test does not have an activate? method, activating as default")

        @a.activate_agent?("test").should == true
      end

      it "should handle exceptions in the activation as false" do
        Agent::Test.expects("activate?").raises(RuntimeError)
        @a.activate_agent?("test").should == false
      end
    end

    describe "#findagentfile" do
      before do
        Config.any_instance.stubs(:configured).returns(true)
        Config.any_instance.stubs(:libdir).returns([@tmpdir])
        Agents.any_instance.stubs(:loadagents).returns(true)
        @a = Agents.new
      end

      it "should support multiple libdirs" do
        Config.any_instance.expects(:libdir).returns([@tmpdir, @tmpdir]).once
        File.expects("exist?").returns(false).twice
        @a.findagentfile("test")
      end

      it "should look for the correct filename in the libdir" do
        File.expects("exist?").with(File.join([@tmpdir, "mcollective", "agent", "test.rb"])).returns(false).once
        @a.findagentfile("test")
      end

      it "should return the full path if the agent is found" do
        agentfile = File.join([@tmpdir, "mcollective", "agent", "test.rb"])
        File.expects("exist?").with(agentfile).returns(true).once
        @a.findagentfile("test").should == agentfile
      end

      it "should return false if no agent is found" do
        @a.findagentfile("foo").should == false
      end
    end

    describe "#include?" do
      it "should correctly report the plugin state" do
        Config.any_instance.stubs(:configured).returns(true)
        Config.any_instance.stubs(:libdir).returns([@tmpdir])
        Agents.any_instance.stubs(:loadagents).returns(true)
        PluginManager.expects("include?").with("test_agent").returns(true)

        @a = Agents.new

        @a.include?("test").should == true
      end
    end

    describe "#agentlist" do
      it "should return the correct agent list" do
        Config.any_instance.stubs(:configured).returns(true)
        Config.any_instance.stubs(:libdir).returns([@tmpdir])
        Agents.any_instance.stubs(:loadagents).returns(true)

        @a = Agents.new("test" => true)
        Agents.agentlist.should == ["test"]
      end
    end
  end
end
