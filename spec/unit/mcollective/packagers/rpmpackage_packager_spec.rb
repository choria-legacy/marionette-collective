#!/usr/bin/env rspec
require 'spec_helper'
require 'mcollective/pluginpackager/rpmpackage_packager'

module MCollective
  module PluginPackager
    describe RpmpackagePackager, :unless => MCollective::Util.windows? do
      let(:plugin) do
        p = mock
        p.stubs(:mcname).returns('mcollective')
        p.stubs(:metadata).returns({:version => '1.0', :name => 'rspec'})
        p.stubs(:revision).returns(1)
        p.stubs(:target_path).returns('rspec_build')
        p
      end

      let(:packager) do
        p = RpmpackagePackager.new(plugin)
        p.instance_variable_set(:@tmpdir, 'rspec_tmp')
        p
      end

      let(:data) do
        {:agent => {:files => ['agent/rspec.rb', 'agent/rspec.ddl']},
         :client => {:files => ['application/rspec.rb']}}
      end

      before :each do
        RpmpackagePackager.any_instance.stubs(:select_command).returns('rpmbuild')
        RpmpackagePackager.any_instance.stubs(:rpmdir).returns('rspec_rpm')
        RpmpackagePackager.any_instance.stubs(:srpmdir).returns('rspec_srpm')
        @packager = packager
      end

      describe '#initialize' do
        it 'should set the instance variables' do
          new_packager = RpmpackagePackager.new(plugin)
          new_packager.instance_variable_get(:@plugin).should == plugin
          new_packager.instance_variable_get(:@package_name).should == 'mcollective-rspec'
          new_packager.instance_variable_get(:@package_name_and_version).should == 'mcollective-rspec-1.0'
          new_packager.instance_variable_get(:@verbose).should == false
          new_packager.instance_variable_get(:@libdir).should == '/usr/libexec/mcollective/mcollective/'
          new_packager.instance_variable_get(:@signature).should == nil
          new_packager.instance_variable_get(:@rpmdir).should == 'rspec_rpm'
          new_packager.instance_variable_get(:@srpmdir).should == 'rspec_srpm'
          new_packager.instance_variable_get(:@keep_artifacts).should == nil
        end

        it 'should fail if no build command is present' do
          RpmpackagePackager.any_instance.stubs(:select_command).returns(nil)
          expect{
            new_packager = RpmpackagePackager.new(plugin)
          }.to raise_error("Cannot build package. 'rpmbuild' or 'rpmbuild-md5' is not present on the system")
        end
      end

      describe '#select_command' do
        it 'should return the command string for rpmbuild if its present' do
          RpmpackagePackager.any_instance.unstub(:select_command)
          PluginPackager.stubs(:command_available?).with('rpmbuild-md5').returns(false)
          PluginPackager.stubs(:command_available?).with('rpmbuild').returns(true)
          @packager.select_command.should == 'rpmbuild'
        end

        it 'should return the command string for rpmbuild-md5 if its present' do
          RpmpackagePackager.any_instance.unstub(:select_command)
          PluginPackager.stubs(:command_available?).with('rpmbuild-md5').returns(true)
          @packager.select_command.should == 'rpmbuild-md5'
        end

        it 'should return nil if neither are present' do
          RpmpackagePackager.any_instance.unstub(:select_command)
          PluginPackager.stubs(:command_available?).with('rpmbuild-md5').returns(false)
          PluginPackager.stubs(:command_available?).with('rpmbuild').returns(false)
          @packager.select_command.should == nil
        end
      end

      describe '#create_packages' do
        before :each do
          @packager.stubs(:puts)
        end

        it 'should run through the complete build process' do
          Dir.expects(:mktmpdir).with('mcollective_packager').returns('rspec_tmp')
          @packager.expects(:prepare_tmpdirs)
          @packager.expects(:make_spec_file)
          @packager.expects(:run_build)
          @packager.expects(:move_packages)
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

      describe '#run_build' do
        it 'should build the packages' do
          @packager.expects(:create_tar).returns('rspec.tgz')
          PluginPackager.expects(:execute_verbosely).with(false).yields
          PluginPackager.expects(:safe_system).with('rpmbuild -ta --quiet rspec.tgz')
          @packager.send(:run_build)
        end

        it 'should sign the packages if a signature is defined' do
          @packager.instance_variable_set(:@signature, true)
          @packager.expects(:create_tar).returns('rspec.tgz')
          PluginPackager.expects(:execute_verbosely).with(false).yields
          PluginPackager.expects(:safe_system).with('rpmbuild -ta --quiet --sign rspec.tgz')
          @packager.send(:run_build)
        end

        it 'should not build silently if verbose is false' do
          @packager.instance_variable_set(:@verbose, true)
          @packager.expects(:create_tar).returns('rspec.tgz')
          PluginPackager.expects(:execute_verbosely).with(true).yields
          PluginPackager.expects(:safe_system).with('rpmbuild -ta rspec.tgz')
          @packager.send(:run_build)
        end

        it 'should write a message and raise an exception if the build fails' do
          @packager.stubs(:create_tar).raises('error')
          @packager.expects(:puts).with('Build process has failed')
          expect{
            @packager.send(:run_build)
          }.to raise_error('error')
        end
      end

      describe '#create_tar' do
        it 'should create the tarball' do
          PluginPackager.expects(:execute_verbosely).with(false).yields
          Dir.expects(:chdir).with('rspec_tmp').yields
          PluginPackager.expects(:safe_system).with('tar -cvzf rspec_tmp/mcollective-rspec-1.0.tgz mcollective-rspec-1.0')
          @packager.send(:create_tar)
        end

        it 'should write a message and raise an exception if the tarball cannot be built' do
          PluginPackager.expects(:execute_verbosely).with(false).raises('error')
          @packager.expects(:puts).with("Could not create tarball - 'rspec_tmp/mcollective-rspec-1.0.tgz'")
          expect{
            @packager.send(:create_tar)
          }.to raise_error('error')
        end
      end

      describe '#move_packages' do
        it 'should copy all the build artifacts to the cwd' do
          File.stubs(:join).with('rspec_rpm', 'noarch', 'mcollective-rspec-*-1.0-1*.noarch.rpm').returns('rspec_rpm/noarch/mcollective-rspec-*-1.0-1.noarch.rpm')
          File.stubs(:join).with('rspec_srpm', 'mcollective-rspec-1.0-1*.src.rpm').returns('rspec_srpm/mcollective-rspec-1.0-1*.src.rpm')
          Dir.stubs(:glob).with('rspec_rpm/noarch/mcollective-rspec-*-1.0-1.noarch.rpm').returns(['1.rpm', '2.rpm'])
          Dir.stubs(:glob).with('rspec_srpm/mcollective-rspec-1.0-1*.src.rpm').returns(['1.src.rpm'])
          FileUtils.expects(:cp).with(['1.rpm', '2.rpm', '1.src.rpm'], '.')
          @packager.send(:move_packages)
        end

        it 'should write a message and raise an exception if the artifacts cannot be copied' do
          Dir.stubs(:glob).raises('error')
          @packager.expects(:puts).with('Could not copy packages to working directory')
          expect{
            @packager.send(:move_packages)
          }.to raise_error('error')
        end
      end

      describe '#make_spec_file' do
        it 'should create a specfile from the erb template' do
          erb = mock
          file = mock
          erb.stubs(:result).returns('<% rspec =%>')
          File.stubs(:dirname).returns('rspec_template')
          File.expects(:read).with('rspec_template/templates/redhat/rpm_spec.erb').returns(erb)
          ERB.expects(:new).with(erb, nil, '-').returns(erb)
          File.expects(:open).with('rspec_tmp/mcollective-rspec-1.0/mcollective-rspec-1.0.spec', 'w').yields(file)
          file.expects(:puts).with('<% rspec =%>')
          @packager.send(:make_spec_file)
        end

        it 'should write a message and raise an exception if it could not create the specfile' do
          ERB.stubs(:new).raises('error')
          @packager.expects(:puts).with("Could not create specfile - 'rspec_tmp/mcollective-rspec-1.0/mcollective-rspec-1.0.spec'")
          expect{
            @packager.send(:make_spec_file)
          }.to raise_error('error')
        end
      end

      describe '#prepare_tmpdirs' do
        before :each do
          pluginfiles = ['/agent/rspec.rb', '/agent/rspec.ddl', '/application/rspec.rb']
          @packager.stubs(:plugin_files).returns(pluginfiles)
        end

        it 'should copy the package content to the tmp build dir' do
          File.stubs(:directory?).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent').returns(false, true)
          File.stubs(:directory?).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/application').returns(false)
          FileUtils.expects(:mkdir_p).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent')
          FileUtils.expects(:mkdir_p).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/application')
          FileUtils.expects(:cp_r).with('/agent/rspec.rb', 'rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent')
          FileUtils.expects(:cp_r).with('/agent/rspec.ddl', 'rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent')
          FileUtils.expects(:cp_r).with('/application/rspec.rb', 'rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/application')
          @packager.send(:prepare_tmpdirs)
        end

        it 'should fail if we do not have permission to create the directory' do
          File.stubs(:directory?).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent').raises(Errno::EACCES)
          @packager.expects(:puts)
          expect{
            @packager.send(:prepare_tmpdirs)
          }.to raise_error(Errno::EACCES)
        end

        it 'should fail if the files we are trying to copy do not exist' do
          File.stubs(:directory?).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent').raises(Errno::ENOENT)
          @packager.expects(:puts)
          expect{
            @packager.send(:prepare_tmpdirs)
          }.to raise_error(Errno::ENOENT)

        end

        it 'should write a message an error if the something else goes wrong and raise an exception' do
          File.stubs(:directory?).with('rspec_tmp/mcollective-rspec-1.0/usr/libexec/mcollective/mcollective/agent').raises('error')
          @packager.expects(:puts)
          expect{
            @packager.send(:prepare_tmpdirs)
          }.to raise_error('error')
        end
      end

      describe '#plugin_files' do
        it 'should return the package files in a single array' do
          files = ['agent/rspec.rb', 'agent/rspec.ddl', 'application/rspec.rb']
          plugin.stubs(:packagedata).returns(data)
          result = @packager.send(:plugin_files)
          (files | result).should == files
        end
      end

      describe '#package_files' do
        it 'should return the package files and ommit the directories' do
          files = ['/rspec', '/rspec/1.rb', '/rspec/2.rb']
          File.expects(:directory?).with('/rspec').returns(true)
          File.expects(:directory?).with('/rspec/1.rb').returns(false)
          File.expects(:directory?).with('/rspec/2.rb').returns(false)
          @packager.send(:package_files, files).should == ['/usr/libexec/mcollective/mcollective/rspec/1.rb', 
                                                           '/usr/libexec/mcollective/mcollective/rspec/2.rb']
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
