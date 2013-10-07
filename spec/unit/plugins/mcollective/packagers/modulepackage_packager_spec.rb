#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/pluginpackager/modulepackage_packager.rb'

module MCollective
  module PluginPackager
    describe ModulepackagePackager, :unless => MCollective::Util.windows? do
      let(:data) do
        {:agent  => {:files => ['./agent/rspec.rb']},
         :common => {:files => ['./agent/rspec.ddl']},
         :client => {:files => ['./application/rspec.rb']}}
      end

      let(:plugin) do
        p = mock
        p.stubs(:mcname).returns('mcollective')
        p.stubs(:metadata).returns({
          :version => '1.0',
          :name => 'rspec',
          :description => 'An rspec.',
          :url => 'http://example.com/rspec/',
        })
        p.stubs(:revision).returns(1)
        p.stubs(:target_path).returns('rspec_build')
        p.stubs(:vendor).returns('puppetlabs')
        p.stubs(:packagedata).returns(data)
        p
      end

      let(:packager) do
        p = ModulepackagePackager.new(plugin)
        p.instance_variable_set(:@tmpdir, 'rspec_tmp')
        p
      end

      before :each do
        ModulepackagePackager.any_instance.stubs(:assert_new_enough_puppet)
        @packager = packager
      end

      describe '#initialize' do
        it 'should set the instance variables' do
          new_packager = ModulepackagePackager.new(plugin)
          new_packager.instance_variable_get(:@plugin).should == plugin
          new_packager.instance_variable_get(:@package_name).should == 'mcollective_rspec'
          new_packager.instance_variable_get(:@verbose).should == false
          new_packager.instance_variable_get(:@keep_artifacts).should == nil
        end

        it 'should fail if no build command is present' do
          ModulepackagePackager.any_instance.stubs(:assert_new_enough_puppet).raises("Cannot build package. 'puppet' is not present on the system")
          expect{
            new_packager = ModulepackagePackager.new(plugin)
          }.to raise_error("Cannot build package. 'puppet' is not present on the system")
        end
      end

      describe '#create_packages' do
        before :each do
          @packager.stubs(:puts)
        end

        it 'should run through the complete build process' do
          Dir.expects(:mktmpdir).with('mcollective_packager').returns('rspec_tmp')
          @packager.expects(:make_module)
          @packager.expects(:run_build)
          @packager.expects(:move_package)
          @packager.expects(:cleanup_tmpdirs)
          @packager.create_packages
        end

        it 'should clean up tmpdirs if keep_artifacts is false' do
          Dir.stubs(:mktmpdir).raises('error')
          @packager.expects(:cleanup_tmpdirs)
          expect{
            packager.create_packages
          }.to raise_error('error')
        end

        it 'should keep the build artifacts if keep_artifacts is true' do
          @packager.instance_variable_set(:@keep_artifacts, true)
          Dir.stubs(:mktmpdir).raises('error')
          @packager.expects(:cleanup_tmpdirs).never
          expect{
            @packager.create_packages
          }.to raise_error('error')
        end
      end

      describe '#assert_new_enough_puppet' do
        before :each do
          ModulepackagePackager.any_instance.unstub(:assert_new_enough_puppet)
        end

        let(:shell) do
          s = mock
          s.stubs(:runcommand)
          s
        end

        it 'should ensure we have a puppet' do
          PluginPackager.expects(:command_available?).with('puppet').returns(false)
          expect {
            packager.send(:assert_new_enough_puppet)
          }.to raise_error('Cannot build package. \'puppet\' is not present on the system.')
        end

        it 'should find the version of puppet' do
          PluginPackager.stubs(:command_available?).with('puppet').returns(true)
          shell.expects(:stdout).returns("3.3.0\n")
          Shell.stubs(:new).with('puppet --version').returns(shell)
          packager.send(:assert_new_enough_puppet)
        end

        it 'should assert the version of puppet is >= 3.3.0' do
          PluginPackager.expects(:command_available?).with('puppet').returns(true)
          Shell.stubs(:new).with('puppet --version').returns(shell)
          shell.stubs(:stdout).returns("3.2.0\n")
          expect {
            packager.send(:assert_new_enough_puppet)
          }.to raise_error('Cannot build package. puppet 3.3.0 or greater required.  We have 3.2.0.')
        end
      end

      describe '#make_module' do
        it 'should copy the package content to the tmp build dir' do
          file = mock()
          File.stubs(:directory?).with('rspec_tmp/manifests').returns(false, true)
          File.stubs(:directory?).with('rspec_tmp/files/agent/mcollective/agent').returns(false, true)
          File.stubs(:directory?).with('rspec_tmp/files/common/mcollective/agent').returns(false, true)
          File.stubs(:directory?).with('rspec_tmp/files/client/mcollective/application').returns(false)
          FileUtils.expects(:mkdir_p).with('rspec_tmp/manifests')
          FileUtils.expects(:mkdir_p).with('rspec_tmp/files/common/mcollective/agent')
          FileUtils.expects(:mkdir_p).with('rspec_tmp/files/agent/mcollective/agent')
          FileUtils.expects(:mkdir_p).with('rspec_tmp/files/client/mcollective/application')
          FileUtils.expects(:cp_r).with('./agent/rspec.rb', 'rspec_tmp/files/agent/mcollective/agent')
          FileUtils.expects(:cp_r).with('./agent/rspec.ddl', 'rspec_tmp/files/common/mcollective/agent')
          FileUtils.expects(:cp_r).with('./application/rspec.rb', 'rspec_tmp/files/client/mcollective/application')
          File.stubs(:open).with('rspec_tmp/manifests/common.pp', 'w').yields(file)
          File.stubs(:open).with('rspec_tmp/manifests/agent.pp', 'w').yields(file)
          File.stubs(:open).with('rspec_tmp/manifests/client.pp', 'w').yields(file)
          File.stubs(:open).with('rspec_tmp/Modulefile', 'w').yields(file)
          File.stubs(:open).with('rspec_tmp/metadata.json', 'w').yields(file)
          File.stubs(:open).with('rspec_tmp/README.md', 'w').yields(file)
          file.expects(:puts).times(6)
          @packager.send(:make_module)
        end
      end

      describe '#run_build' do
        before :each do
          Dir.stubs(:chdir).yields
        end

        it 'should build the packages' do
          PluginPackager.expects(:execute_verbosely).with(false).yields
          PluginPackager.expects(:safe_system).with('puppet module build')
          @packager.send(:run_build)
        end

        it 'should not build silently if verbose is false' do
          @packager.instance_variable_set(:@verbose, true)
          PluginPackager.expects(:execute_verbosely).with(true).yields
          PluginPackager.expects(:safe_system).with('puppet module build')
          @packager.send(:run_build)
        end

        it 'should write a message and raise an exception if the build fails' do
          Dir.stubs(:chdir).raises('error')
          @packager.expects(:puts).with('Build process has failed')
          expect{
            @packager.send(:run_build)
          }.to raise_error('error')
        end
      end

      describe '#move_package' do
        it 'should copy all the build artifacts to the cwd' do
          File.stubs(:join).with('rspec_tmp', 'pkg', 'puppetlabs-mcollective_rspec-1.0.tar.gz').returns('1.tar.gz')
          FileUtils.expects(:cp).with('1.tar.gz', '.')
          @packager.send(:move_package)
        end

        it 'should write a message and raise an exception if the artifacts cannot be copied' do
          FileUtils.stubs(:cp).raises('error')
          @packager.expects(:puts).with('Could not copy package to working directory')
          expect{
            @packager.send(:move_package)
          }.to raise_error('error')
        end
      end

      describe '#cleanup_tmpdirs' do
        it 'should remove the tmp dirs' do
          File.stubs(:directory?).with('rspec_tmp').returns(true)
          FileUtils.expects(:rm_r).with('rspec_tmp')
          @packager.send(:cleanup_tmpdirs)
        end

        it 'should write a message and raise an exception if it cannot remove the tmp dirs' do
          File.stubs(:directory?).raises('error')
          @packager.expects(:puts).with("Could not remove temporary build directory - 'rspec_tmp'")
          expect{
            @packager.send(:cleanup_tmpdirs)
          }.to raise_error('error')
        end
      end
    end
  end
end
