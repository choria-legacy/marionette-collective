#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module PluginPackager
    describe AgentDefinition do
      before :each do
        PluginPackager.expects(:get_metadata).once.returns({:name => "foo", :version => 1})
      end

      describe "#initialize" do
        it "should replace spaces in the package name with dashes" do
          AgentDefinition.any_instance.expects(:common)
          agent = AgentDefinition.new(".", "test package", nil, nil, nil, nil, [], {}, "agent")
          agent.metadata[:name].should == "test-package"
        end

        it "should set dependencies if present" do
          AgentDefinition.any_instance.expects(:common)
          agent = AgentDefinition.new(".", "test-package", nil, nil, nil, nil, [:name => "foo", :version => nil], {}, "agent")
          agent.dependencies.should == [{:name => "foo", :version => nil}, {:name => "mcollective-common", :version => nil}]
        end

        it "should set mc name and version" do
          AgentDefinition.any_instance.expects(:common)
          agent = AgentDefinition.new(".", "test-package", nil, nil, nil, nil, [], {:mcname =>"pe-mcollective-common", :mcversion =>"1.2"}, "agent")
          agent.mcname.should == "pe-mcollective-common"
          agent.mcversion.should == "1.2"
        end
      end

      describe "#identify_packages" do
        it "should attempt to identify all agent packages" do
          AgentDefinition.any_instance.expects(:common).once.returns(:check)
          AgentDefinition.any_instance.expects(:agent).once.returns(:check)
          AgentDefinition.any_instance.expects(:client).once.returns(:check)

          agent = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          agent.packagedata[:common].should == :check
          agent.packagedata[:agent].should == :check
          agent.packagedata[:client].should == :check
        end
      end

      describe "#agent" do
        before do
          AgentDefinition.any_instance.expects(:client).once
        end

        it "should not populate the agent files if the agent directory is empty" do
          AgentDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).returns(false)
          agent = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          agent.packagedata[:agent].should == nil
        end

        it "should add the agent file if the agent directory and implementation file is present" do
          AgentDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.stubs(:check_dir_present).returns(true)
          File.stubs(:join).with(".", "agent").returns("tmpdir/agent")
          File.stubs(:join).with("tmpdir/agent", "*.ddl").returns("tmpdir/agent/*.ddl")
          File.stubs(:join).with("tmpdir/agent", "*").returns("tmpdir/agent/*")
          Dir.stubs(:glob).with("tmpdir/agent/*.ddl").returns([])
          Dir.stubs(:glob).with("tmpdir/agent/*").returns(["implementation.rb"])

          agent = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          agent.packagedata[:agent][:files].should == ["implementation.rb"]
        end

        it "should add common package as dependency if present" do
          AgentDefinition.any_instance.expects(:common).returns({:files=> ["test.rb"]})
          PluginPackager.expects(:check_dir_present).with("tmpdir/agent").returns(true)
          File.stubs(:join).returns("/tmp")
          File.stubs(:join).with(".", "agent").returns("tmpdir/agent")
          File.stubs(:join).with(".", "aggregate").returns("tmpdir/aggregate")
          Dir.stubs(:glob).returns([])

          agent = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          agent.packagedata[:agent][:dependencies].should == [{:name => "mcollective-common", :version => nil},
                                                              {:name => "mcollective-foo-common", :version =>1}]
        end
      end

      describe "#common" do
        it "should populate the common files if there are any" do
          AgentDefinition.any_instance.expects(:agent)
          AgentDefinition.any_instance.expects(:client)
          File.expects(:join).with(".", "data", "**").returns("datadir")
          File.expects(:join).with(".", "util", "**", "**").returns("utildir")
          File.expects(:join).with(".", "agent", "*.ddl").returns("ddldir")
          File.expects(:join).with(".", "validator", "**").returns("validatordir")
          Dir.expects(:glob).with("datadir").returns(["data.rb"])
          Dir.expects(:glob).with("utildir").returns(["util.rb"])
          Dir.expects(:glob).with("validatordir").returns(["validator.rb"])
          Dir.expects(:glob).with("ddldir").returns(["agent.ddl"])

          common = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          common.packagedata[:common][:files].should == ["data.rb", "util.rb", "validator.rb", "agent.ddl"]
        end

        it "should raise an exception if the ddl file isn't present" do
          File.expects(:join).with(".", "data", "**").returns("datadir")
          File.expects(:join).with(".", "util", "**", "**").returns("utildir")
          File.expects(:join).with(".", "agent", "*.ddl").returns("ddldir")
          File.expects(:join).with(".", "agent").returns("ddldir")
          File.expects(:join).with(".", "validator", "**").returns("validatordir")
          Dir.expects(:glob).with("datadir").returns(["data.rb"])
          Dir.expects(:glob).with("utildir").returns(["util.rb"])
          Dir.expects(:glob).with("validatordir").returns(["validator.rb"])
          Dir.expects(:glob).with("ddldir").returns([])

          expect{
            common = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          }.to raise_error(RuntimeError, "cannot create package - No ddl file found in ddldir")
        end
      end

      describe "#client" do
        before do
          AgentDefinition.any_instance.expects(:agent).returns(nil)
          File.expects(:join).with(".", "application").returns("clientdir")
          File.expects(:join).with(".", "bin").returns("bindir")
          File.expects(:join).with(".", "aggregate").returns("aggregatedir")
        end

        it "should populate client files if all directories are present" do
          AgentDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).times(3).returns(true)
          File.expects(:join).with("clientdir", "*").returns("clientdir/*")
          File.expects(:join).with("bindir", "*").returns("bindir/*")
          File.expects(:join).with("aggregatedir", "*").returns("aggregatedir/*")
          Dir.expects(:glob).with("clientdir/*").returns(["client.rb"])
          Dir.expects(:glob).with("bindir/*").returns(["bin.rb"])
          Dir.expects(:glob).with("aggregatedir/*").returns(["aggregate.rb"])

          client = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          client.packagedata[:client][:files].should == ["client.rb", "bin.rb", "aggregate.rb"]
        end

        it "should not populate client files if directories are not present" do
          AgentDefinition.any_instance.expects(:common).returns(nil)
          PluginPackager.expects(:check_dir_present).times(3).returns(false)

          client = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          client.packagedata[:client].should == nil
        end

        it "should add common package as dependency if present" do
          AgentDefinition.any_instance.expects(:common).returns("common")
          PluginPackager.expects(:check_dir_present).times(3).returns(true)
          File.expects(:join).with("clientdir", "*").returns("clientdir/*")
          File.expects(:join).with("bindir", "*").returns("bindir/*")
          File.expects(:join).with("aggregatedir", "*").returns("aggregatedir/*")
          Dir.expects(:glob).with("clientdir/*").returns(["client.rb"])
          Dir.expects(:glob).with("bindir/*").returns(["bin.rb"])
          Dir.expects(:glob).with("aggregatedir/*").returns(["aggregate.rb"])

          client = AgentDefinition.new(".", nil, nil, nil, nil, nil, [], {}, "agent")
          client.packagedata[:client][:dependencies].should == [{:name => "mcollective-common", :version => nil},
                                                                {:name => "mcollective-foo-common", :version => 1}]
        end
      end
    end
  end
end
