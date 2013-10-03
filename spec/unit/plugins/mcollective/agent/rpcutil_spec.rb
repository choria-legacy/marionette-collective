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
    end
  end
end