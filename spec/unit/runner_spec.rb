#!/usr/bin/env rspec

require 'spec_helper'

module MCollective
  describe Runner do
    let(:config) do
      c = mock
      c.stubs(:loadconfig)
      c.stubs(:configured).returns(true)
      c.stubs(:mode=)
      c.stubs(:direct_addressing).returns(true)
      c.stubs(:registerinterval).returns(1)
      c.stubs(:soft_shutdown).returns(false)
      c
    end

    let(:stats) { mock }

    let(:security) do
      s = mock
      s.stubs(:initiated_by=)
      s
    end

    let(:connector) do
      c = mock
      c.stubs(:connect)
      c.stubs(:disconnect)
      c
    end

    let(:agents) { mock }

    let(:receiver_thread) do
      rt = mock
      rt
    end

    before :each do
      Config.stubs(:instance).returns(config)
      PluginManager.stubs(:[]).with('global_stats').returns(stats)
      PluginManager.stubs(:[]).with('security_plugin').returns(security)
      PluginManager.stubs(:[]).with('connector_plugin').returns(connector)
      Agents.stubs(:new).returns(agents)
    end

    describe 'initialize' do
      it 'should set up the signal handlers when not on windows' do
        Util.stubs(:windows).returns(false)
        Signal.expects(:trap).with('USR1')
        Signal.expects(:trap).with('USR2')
        Runner.new(nil)
      end

      it 'should not set up the signal handlers when on windows' do
        Util.stubs(:windows?).returns(true)
        Signal.expects(:trap).with('USR1').never
        Signal.expects(:trap).with('USR2').never

        Util.expects(:setup_windows_sleeper)
        Runner.new(nil)
      end

      it 'should log a message when it cannot initialize the runner' do
        Config.stubs(:instance).raises('failure')
        Log.expects(:error).times(3)
        expect {
          Runner.new(nil)
        }.to raise_error 'failure'
      end
    end

    describe '#main_loop' do
      let(:runner) do
        Runner.new(nil)
      end

      let(:receiver_thread) do
        rt = mock
        rt.stubs(:alive?).returns(false)
        rt
      end

      let(:agent_thread) do
        at = mock
        at.stubs(:alive?).returns(true)
        at.expects(:join)
        at
      end

      before :each do
        Log.stubs(:debug)
        Log.stubs(:info)
        Log.stubs(:warn)
        Log.stubs(:error)
        runner.stubs(:start_receiver_thread).returns(receiver_thread)
      end

      context 'stopping' do
        it 'should stop normally' do
          receiver_thread.stubs(:alive?).returns(true)
          runner.instance_variable_set(:@state, :stopping)
          runner.expects(:stop_threads)
          runner.main_loop
        end

        it 'should not do a soft_shutdown on windows' do
          config.stubs(:soft_shutdown).returns(true)
          Util.stubs(:windows?).returns(true)
          Log.expects(:warn).with("soft_shutdown specified. This feature is not available on Windows. Shutting down normally.")
          runner.instance_variable_set(:@state, :stopping)
          runner.main_loop
        end

        it 'should do a soft_shutdown' do
          config.stubs(:soft_shutdown).returns(true)
          Util.stubs(:windows?).returns(false)
          runner.instance_variable_set(:@state, :stopping)
          runner.instance_variable_set(:@agent_threads, [agent_thread])
          runner.main_loop
        end
      end

      # Because paused is not a terminal state, we raise after testing pause
      # which forces a run. This means checks like #stop_threads will happen twice
      context 'pausing' do
        before :each do
          receiver_thread.stubs(:alive?).returns(false)
        end

        it 'should pause' do
          runner.instance_variable_set(:@state, :pausing)
          runner.expects(:stop_threads).twice
          runner.expects(:sleep).with(0.1).raises("error")
          runner.main_loop
        end

        it 'should resume' do
          runner.instance_variable_set(:@state, :unpausing)
          runner.expects(:stop_threads)
          runner.expects(:start_receiver_thread).returns(receiver_thread)
          runner.expects(:sleep).with(0.1).raises("error")
          runner.main_loop
        end
      end
    end

    context 'action methods' do
      let(:runner) do
        Runner.new(nil)
      end

      describe '#stop' do
        it 'should change the state to stopping' do
          runner.instance_variable_set(:@state, :running)
          runner.stop
          runner.state.should == :stopping
        end
      end

      describe '#pause' do
        it 'should change the state to pausing' do
          runner.instance_variable_set(:@state, :running)
          runner.pause
          runner.state.should == :pausing
        end

        it 'should fail if state is not running' do
          Log.expects(:error).with('Cannot pause MCollective while not in a running state')
          runner.pause
        end
      end

      describe '#resume' do
        it 'should change the state to unpausing' do
          runner.instance_variable_set(:@state, :paused)
          runner.resume
          runner.state.should == :unpausing
        end

        it 'should fail if state is not paused' do
          runner.instance_variable_set(:@state, :running)
          Log.expects(:error).with('Cannot unpause MCollective when it is not paused')
          runner.resume
        end
      end

      describe '#receiver_thread' do
        let(:runner) do
          Runner.new(nil)
        end

        let(:registration_agent) do
          ra = mock
          ra.stubs(:run)
          ra
        end

        let(:request) do
          r = mock
          r.stubs(:agent).returns("rspec")
          r
        end

        before :each do
          PluginManager.stubs(:[]).with("registration_plugin").returns(registration_agent)
          Data.stubs(:load_data_sources)
          # Make sure the deprecated controller messages don't make their way
          # back in
          Util.expects(:subscribe).never
          Util.expects(:make_subscriptions).never
        end

        it 'should receive a message and spawn an agent thread' do
          runner.expects(:receive).returns(request)
          runner.expects(:agentmsg).with(request)
          runner.instance_variable_set(:@exit_receiver_thread, true)
          runner.send(:receiver_thread)
        end

        it 'should load agents before data plugins' do
          load_order = sequence('load_order')
          Agents.expects(:new).in_sequence(load_order)
          Data.expects(:load_data_sources).in_sequence(load_order)
          runner.expects(:receive).returns(request)
          runner.expects(:agentmsg).with(request)
          runner.instance_variable_set(:@exit_receiver_thread, true)
          runner.send(:receiver_thread)
        end

        it 'should warn when a received message has expired' do
          runner.expects(:receive).raises(MsgTTLExpired)
          runner.instance_variable_set(:@exit_receiver_thread, true)
          Log.expects(:warn)
          runner.send(:receiver_thread)
        end

        it 'should log if a message was received by not directed at the server' do
          runner.expects(:receive).raises(NotTargettedAtUs)
          runner.instance_variable_set(:@exit_receiver_thread, true)
          Log.expects(:debug).with("Message does not pass filters, ignoring")
          runner.send(:receiver_thread)
        end

        it 'should back off on MessageNotReceived and UnexpectedMessageType' do
          runner.expects(:receive).raises(MessageNotReceived.new(1))
          runner.instance_variable_set(:@exit_receiver_thread, true)
          Log.expects(:warn)
          Log.expects(:info).with("sleeping for suggested 1 seconds")
          runner.expects(:sleep).with(1)
          runner.send(:receiver_thread)
        end
      end
    end
  end
end
