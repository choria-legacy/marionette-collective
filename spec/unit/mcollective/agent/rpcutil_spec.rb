#!/usr/bin/env rspec

@agent_file = File.join(File.dirname(__FILE__), '../../../../../', 'plugins', 'mcollective', 'agent', 'rpcutil.rb')

require 'spec_helper'
require @agent_file

module MCollective
  module Agent
    describe Rpcutil do
      module Facts
        def self.[](fact)
          {'fact1' => 'value1', 'fact2' => 'value2', 'fact3' => 'value3'}[fact]
        end
      end

      before :each do
        @agent = MCollective::Test::LocalAgentTest.new('rpcutil', :agent_file => @agent_file).plugin
      end

      describe '#inventory' do
        it 'should return the node inventory' do
          facts = mock
          facts.stubs(:get_facts).returns({:key => 'value'})
          Agents.stubs(:agentlist).returns(['test'])
          PluginManager.stubs(:[]).with('facts_plugin').returns(facts)
          MCollective.stubs(:version).returns('2.4.0')
          PluginManager.stubs(:grep).with(/_data$/).returns(['test_data'])
          Config.any_instance.stubs(:classesfile).returns('classes.txt')
          File.stubs(:exist?).with('classes.txt').returns(true)
          File.stubs(:readlines).with('classes.txt').returns(['class1', 'class2'])
          result = @agent.call(:inventory)
          result.should be_successful
          result.should have_data_items({:agents=>["test"],
                                        :facts=>{:key=>"value"},
                                        :version=>"2.4.0",
                                        :classes=>["class1", "class2"],
                                        :main_collective=>"mcollective",
                                        :collectives=>["production", "staging"],
                                        :data_plugins=>["test_data"]})
        end
      end

      describe '#get_fact' do
        it 'should return the value of the queried fact' do
          result = @agent.call(:get_fact, :fact => 'fact1')
          result.should be_successful
          result.should have_data_items({:fact => 'fact1', :value => 'value1'})
        end

        it 'should not break if the fact is not present' do
          result = @agent.call(:get_fact, :fact => 'fact4')
          result.should be_successful
          result.should have_data_items({:fact => 'fact4', :value => nil })
        end
      end

      describe '#get_facts' do
        it 'should return the value of the supplied facts' do
          result = @agent.call(:get_facts, :facts => 'fact1, fact3')
          result.should be_successful
          result.should have_data_items(:values => {'fact1' => 'value1', 'fact3' => 'value3'})
        end

        it 'should not break if the facts are not present' do
          result = @agent.call(:get_facts, :facts => 'fact4, fact5')
          result.should be_successful
          result.should have_data_items(:values => {'fact4' => nil, 'fact5' => nil})
        end
      end

      describe '#daemon_stats' do
        it "it should return the daemon's statistics" do
          stats = {:threads => 2,
                   :agents => ['agent1', 'agent2'],
                   :pid => 42,
                   :times => 12345,
                   :configfile => '/etc/mcollective/server.cfg',
                   :version => '2.4.0',
                   :stats => {}}
          config = mock
          Config.stubs(:instance).returns(config)
          MCollective.stubs(:version).returns('2.4.0')
          config.stubs(:configfile).returns('/etc/mcollective/server.cfg')
          PluginManager.stubs(:[]).returns(stats)
          result = @agent.call(:daemon_stats)
          result.should be_successful
          stats.delete(:stats)
          result.should have_data_items(stats)
        end
      end

      describe '#agent_inventory' do
        it 'should return the agent inventory' do
          meta = {:license => 'ASL 2',
                  :description => 'Agent for testing',
                  :url => 'http://www.theurl.net',
                  :version => '1',
                  :author => 'rspec'}
          agent = mock
          agent.stubs(:meta).returns(meta)
          agent.stubs(:timeout).returns(2)
          PluginManager.stubs(:[]).with('test_agent').returns(agent)
          Agents.stubs(:agentlist).returns(['test'])

          result = @agent.call(:agent_inventory)
          result.should be_successful
          result.should have_data_items(:agents => [meta.merge({:timeout => 2, :name => 'test', :agent => 'test'})])
        end
      end

      describe '#get_config_item' do
        it 'should return the value of the requested config item' do
          Config.any_instance.stubs(:respond_to?).with(:main_collective).returns(true)
          result = @agent.call(:get_config_item, :item => :main_collective)
          result.should be_successful
          result.should have_data_items(:item => :main_collective, :value => "mcollective")
        end

        it 'should fail if the config item has not been defined' do
          result = @agent.call(:get_config_item, :item => :failure)
          result.should be_aborted_error
        end
      end

      describe '#ping' do
        it 'should return the current time on the host' do
          Time.expects(:now).returns("123456")
          result = @agent.call(:ping)
          result.should be_successful
          result.should have_data_items(:pong => 123456)
        end
      end

      describe '#collective_info' do
        it 'should return the main collective and list of defined collectives' do
          result = @agent.call(:collective_info)
          result.should be_successful
          result.should have_data_items({:main_collective => 'mcollective', :collectives => ['production', 'staging']})
        end
      end

      describe '#get_data' do
        let(:query_data) do
          {:key1 => 'value1', :key2 => 'value2'}
        end

        let(:data) do
          mock
        end

        let(:ddl) do
          mock
        end

        it 'should return the data results if a query has been specified' do
          data.stubs(:lookup).with('query').returns(query_data)
          Data.stubs(:ddl).with('test_data').returns(ddl)
          Data.stubs(:ddl_transform_input).with(ddl, 'query').returns('query')
          Data.stubs(:[]).with('test_data').returns(data)
          result = @agent.call(:get_data, :source => 'test_data', :query => 'query')
          result.should be_successful
          result.should have_data_items(:key1 => 'value1', :key2 => 'value2')
        end

        it 'should return the data results if no query has been specified' do
          data.stubs(:lookup).with(nil).returns(query_data)
          Data.stubs(:[]).with('test_data').returns(data)
          result = @agent.call(:get_data, :source => 'test_data')
          result.should be_successful
          result.should have_data_items(:key1 => 'value1', :key2 => 'value2')
        end
      end
    end
  end
end
