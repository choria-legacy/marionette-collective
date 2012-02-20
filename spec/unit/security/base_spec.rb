#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  module Security
    describe Base do
      before do
        @config = mock("config")
        @config.stubs(:identity).returns("test")
        @config.stubs(:configured).returns(true)
        @config.stubs(:topicsep).returns(".")
        @config.stubs(:topicprefix).returns("/topic/")

        @stats = mock("stats")

        @time = Time.now
        ::Time.stubs(:now).returns(@time)

        MCollective::Log.stubs(:debug).returns(true)

        MCollective::PluginManager << {:type => "global_stats", :class => @stats}
        MCollective::Config.stubs("instance").returns(@config)
        MCollective::Util.stubs("empty_filter?").returns(false)

        @plugin = Base.new
      end

      describe "#should_process_msg?" do
        it "should correctly validate messages" do
          m = mock
          m.stubs(:expected_msgid).returns("rspec")

          @plugin.should_process_msg?(m, "rspec").should == true

          expect {
            @plugin.should_process_msg?(m, "fail").should == true
          }.to raise_error MsgDoesNotMatchRequestID
        end

        it "should not test messages without expected_msgid" do
          m = mock
          m.stubs(:expected_msgid).returns(nil)

          @plugin.should_process_msg?(m, "rspec").should == true
        end
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
          MCollective::Log.expects(:debug).with("Passing based on identity").once

          @plugin.validate_filter?({"identity" => ["test"]}).should == true
        end

        it "should fail for known identity" do
          MCollective::Util.stubs("has_identity?").with("test").returns(false)

          @stats.stubs(:passed).never
          @stats.stubs(:filtered).once

          MCollective::Log.expects(:debug).with("Message failed the filter checks").once
          MCollective::Log.expects(:debug).with("Failed based on identity").once

          @plugin.validate_filter?({"identity" => ["test"]}).should == false
        end

        it "should treat multiple identity filters correctly" do
          MCollective::Util.stubs("has_identity?").with("foo").returns(false)
          MCollective::Util.stubs("has_identity?").with("bar").returns(true)

          @stats.stubs(:passed).once
          @stats.stubs(:filtered).never

          MCollective::Log.expects(:debug).with("Message passed the filter checks").once
          MCollective::Log.expects(:debug).with("Passing based on identity").once

          @plugin.validate_filter?({"identity" => ["foo", "bar"]}).should == true
        end

        it "should fail if no identity matches are found" do
          MCollective::Util.stubs("has_identity?").with("foo").returns(false)
          MCollective::Util.stubs("has_identity?").with("bar").returns(false)

          @stats.stubs(:passed).never
          @stats.stubs(:filtered).once

          MCollective::Log.expects(:debug).with("Message failed the filter checks").once
          MCollective::Log.expects(:debug).with("Failed based on identity").once

          @plugin.validate_filter?({"identity" => ["foo", "bar"]}).should == false
        end
      end

      describe "#create_reply" do
        it "should return correct data" do
          expected = {:senderid => "test",
            :requestid => "reqid",
            :senderagent => "agent",
            :msgtime => @time.to_i,
            :body => "body"}

          @plugin.create_reply("reqid", "agent", "body").should == expected
        end
      end

      describe "#create_request" do
        it "should return correct data" do
          expected = {:body => "body",
            :senderid => "test",
            :requestid => "reqid",
            :callerid => "uid=#{Process.uid}",
            :agent => "discovery",
            :collective => "mcollective",
            :filter => "filter",
            :ttl => 20,
            :msgtime => @time.to_i}

          @plugin.create_request("reqid", "filter", "body", :server, "discovery", "mcollective", 20).should == expected
        end

        it "should set the callerid when appropriate" do
          expected = {:body => "body",
            :senderid => "test",
            :requestid => "reqid",
            :agent => "discovery",
            :collective => "mcollective",
            :filter => "filter",
            :callerid => "callerid",
            :ttl => 60,
            :msgtime => @time.to_i}

          @plugin.stubs(:callerid).returns("callerid")
          @plugin.create_request("reqid", "filter", "body", :client, "discovery", "mcollective").should == expected
        end
      end

      describe "#valid_callerid?" do
        it "should not pass invalid callerids" do
          @plugin.valid_callerid?("foo-bar").should == false
          @plugin.valid_callerid?("foo=bar=baz").should == false
          @plugin.valid_callerid?('foo=bar\baz').should == false
          @plugin.valid_callerid?("foo=bar/baz").should == false
          @plugin.valid_callerid?("foo=bar|baz").should == false
        end

        it "should pass valid callerids" do
          @plugin.valid_callerid?("cert=foo-bar").should == true
          @plugin.valid_callerid?("uid=foo.bar").should == true
          @plugin.valid_callerid?("uid=foo.bar.123").should == true
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
          @plugin.encoderequest(nil, nil, nil)
        end
      end

      describe "#encodereply" do
        it "should log an error when not implimented" do
          MCollective::Log.expects(:error).with("encodereply is not implimented in MCollective::Security::Base")
          @plugin.encodereply(nil, nil, nil)
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
end
