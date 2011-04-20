#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

module MCollective::Security
    describe Base do
        before do
            @config = mock("config")
            @config.stubs(:identity).returns("test")
            @config.stubs(:configured).returns(true)

            @stats = mock("stats")

            @time = Time.now.to_i
            ::Time.stubs(:now).returns(@time)

            MCollective::Log.stubs(:debug).returns(true)

            MCollective::PluginManager << {:type => "global_stats", :class => @stats}
            MCollective::Config.stubs("instance").returns(@config)
            MCollective::Util.stubs("empty_filter?").returns(false)

            @plugin = Base.new
        end

        describe "#validate_filter?" do
            it "should pass on empty filter" do
                MCollective::Util.stubs("empty_filter?").returns(true)

                @stats.stubs(:passed).once
                @stats.stubs(:filtered).never
                @stats.stubs(:passed).never

                MCollective::Log.expects(:debug).with("Message passed the filter checks").once

                @plugin.validate_filter?({}).should == true
            end

            it "should pass for known classes" do
                MCollective::Util.stubs("has_cf_class?").with("foo").returns(true)

                @stats.stubs(:passed).once
                @stats.stubs(:filtered).never

                MCollective::Log.expects(:debug).with("Message passed the filter checks").once
                MCollective::Log.expects(:debug).with("Passing based on configuration management class foo").once

                @plugin.validate_filter?({"cf_class" => ["foo"]}).should == true
            end

            it "should fail for unknown classes" do
                MCollective::Util.stubs("has_cf_class?").with("foo").returns(false)

                @stats.stubs(:filtered).once
                @stats.stubs(:passed).never

                MCollective::Log.expects(:debug).with("Message failed the filter checks").once
                MCollective::Log.expects(:debug).with("Failing based on configuration management class foo").once

                @plugin.validate_filter?({"cf_class" => ["foo"]}).should == false
            end

            it "should pass for known agents" do
                MCollective::Util.stubs("has_agent?").with("foo").returns(true)

                @stats.stubs(:passed).once
                @stats.stubs(:filtered).never

                MCollective::Log.expects(:debug).with("Message passed the filter checks").once
                MCollective::Log.expects(:debug).with("Passing based on agent foo").once

                @plugin.validate_filter?({"agent" => ["foo"]}).should == true
            end

            it "should fail for unknown agents" do
                MCollective::Util.stubs("has_agent?").with("foo").returns(false)

                @stats.stubs(:filtered).once
                @stats.stubs(:passed).never

                MCollective::Log.expects(:debug).with("Message failed the filter checks").once
                MCollective::Log.expects(:debug).with("Failing based on agent foo").once

                @plugin.validate_filter?({"agent" => ["foo"]}).should == false
            end

            it "should pass for known facts" do
                MCollective::Util.stubs("has_fact?").with("fact", "value", "operator").returns(true)

                @stats.stubs(:passed).once
                @stats.stubs(:filtered).never

                MCollective::Log.expects(:debug).with("Message passed the filter checks").once
                MCollective::Log.expects(:debug).with("Passing based on fact fact operator value").once

                @plugin.validate_filter?({"fact" => [{:fact => "fact", :operator => "operator", :value => "value"}]}).should == true
            end

            it "should fail for unknown facts" do
                MCollective::Util.stubs("has_fact?").with("fact", "value", "operator").returns(false)

                @stats.stubs(:filtered).once
                @stats.stubs(:passed).never

                MCollective::Log.expects(:debug).with("Message failed the filter checks").once
                MCollective::Log.expects(:debug).with("Failing based on fact fact operator value").once

                @plugin.validate_filter?({"fact" => [{:fact => "fact", :operator => "operator", :value => "value"}]}).should == false
            end

            it "should pass for known identity" do
                MCollective::Util.stubs("has_identity?").with("test").returns(true)

                @stats.stubs(:passed).once
                @stats.stubs(:filtered).never

                MCollective::Log.expects(:debug).with("Message passed the filter checks").once
                MCollective::Log.expects(:debug).with("Passing based on identity = test").once

                @plugin.validate_filter?({"identity" => ["test"]}).should == true
            end

            it "should fail for known identity" do
                MCollective::Util.stubs("has_identity?").with("test").returns(false)

                @stats.stubs(:passed).never
                @stats.stubs(:filtered).once

                MCollective::Log.expects(:debug).with("Message failed the filter checks").once
                MCollective::Log.expects(:debug).with("Failed based on identity = test").once

                @plugin.validate_filter?({"identity" => ["test"]}).should == false
            end
        end

        describe "#create_reply" do
            it "should return correct data" do
                expected = {:senderid => "test",
                            :requestid => "reqid",
                            :senderagent => "agent",
                            :msgtarget => "target",
                            :msgtime => @time,
                            :body => "body"}

                @plugin.create_reply("reqid", "agent", "target", "body").should == expected
            end
        end

        describe "#create_request" do
            it "should return correct data" do
                expected = {:body => "body",
                            :senderid => "test",
                            :requestid => "reqid",
                            :msgtarget => "target",
                            :filter => "filter",
                            :msgtime => @time}

                @plugin.create_request("reqid", "target", "filter", "body", :server).should == expected
            end

            it "should set the callerid when appropriate" do
                expected = {:body => "body",
                            :senderid => "test",
                            :requestid => "reqid",
                            :msgtarget => "target",
                            :filter => "filter",
                            :callerid => "callerid",
                            :msgtime => @time}

                @plugin.stubs(:callerid).returns("callerid")
                @plugin.create_request("reqid", "target", "filter", "body", :client).should == expected
            end
        end

        describe "#callerid" do
            it "should return a unix UID based callerid" do
                @plugin.callerid.should == "uid=#{Process.uid}"
            end
        end

        describe "#validrequest?" do
            it "should log an error when not implimented" do
                MCollective::Log.expects(:error).with("validrequest? is not implimented in MCollective::Security::Base")
                @plugin.validrequest?(nil)
            end
        end

        describe "#encoderequest" do
            it "should log an error when not implimented" do
                MCollective::Log.expects(:error).with("encoderequest is not implimented in MCollective::Security::Base")
                @plugin.encoderequest(nil, nil, nil, nil)
            end
        end

        describe "#encodereply" do
            it "should log an error when not implimented" do
                MCollective::Log.expects(:error).with("encodereply is not implimented in MCollective::Security::Base")
                @plugin.encodereply(nil, nil, nil, nil)
            end
        end

        describe "#decodemsg" do
            it "should log an error when not implimented" do
                MCollective::Log.expects(:error).with("decodemsg is not implimented in MCollective::Security::Base")
                @plugin.decodemsg(nil)
            end
        end
    end
end
