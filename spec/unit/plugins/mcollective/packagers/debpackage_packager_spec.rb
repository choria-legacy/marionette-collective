#!/usr/bin/env rspec
require 'spec_helper'
require File.dirname(__FILE__) + '/../../../../../plugins/mcollective/pluginpackager/debpackage_packager.rb'

module MCollective
  module PluginPackager
    describe DebpackagePackager, :unless => MCollective::Util.windows? do

      let(:plugin) do
        plugin = mock
        plugin.stubs(:mcname).returns('mcollective')
        plugin.stubs(:metadata).returns({ :name => 'rspec', :version => '1.0'})
        plugin.stubs(:target_path).returns('/rspec')
        plugin
      end

      let(:packager) do
        p = DebpackagePackager.new(plugin)
        p.instance_variable_set(:@plugin, plugin)
        p.instance_variable_set(:@tmpdir, 'rspec_tmp')
        p.instance_variable_set(:@build_dir, 'rspec_build')
        p.instance_variable_set(:@libdir, 'rspec_libdir')
        p
      end

      let(:data) do
        {:files => ['/rspec/agent/file.rb', '/rspec/agent/file.ddl', '/rspec/application/file.rb'],
         :dependencies => [{:name => 'dep1', :version => nil, :revision => nil},
                          {:name => 'dep2', :version => '1.1', :revision => nil},
                          {:name => 'dep3', :version => '1.1', :revision => 2}],
         :plugindependency => {:name => 'mcollective-rspec-common'}}
      end

      before :each do
        PluginPackager.stubs(:command_available?).returns(true)
      end

      describe '#initialize' do
        it 'should set the instance variables' do
          new_packager = DebpackagePackager.new(plugin)
          new_packager.instance_variable_get(:@plugin).should == plugin
          new_packager.instance_variable_get(:@verbose).should == false
          new_packager.instance_variable_get(:@libdir).should == '/usr/share/mcollective/plugins/mcollective/'
          new_packager.instance_variable_get(:@signature).should == nil
          new_packager.instance_variable_get(:@package_name).should == 'mcollective-rspec'
        end

        it 'should fail if debuild is not present on the system' do
          PluginPackager.stubs(:command_available?).with('debuild').returns(false)
          expect{
            DebpackagePackager.new(plugin)
          }.to raise_error("Cannot build package. 'debuild' is not present on the system.")
        end
      end

      describe '#create_packages' do
        it 'should run through the complete build process' do
          build_dir = 'mc-tmp/mcollective-rspec_1.0'
          tmpdir = 'mc-tmp'
          packager.stubs(:puts)
          Dir.expects(:mktmpdir).with('mcollective_packager').returns(tmpdir)
          Dir.expects(:mkdir).with(build_dir)
          packager.expects(:create_debian_dir)
          plugin.stubs(:packagedata).returns({:agent => data})
          packager.expects(:prepare_tmpdirs).with(data)
          packager.expects(:create_install_file).with(:agent, data)
          packager.expects(:create_pre_and_post_install).with(:agent)
          packager.expects(:create_debian_files)
          packager.expects(:create_tar)
          packager.expects(:run_build)
          packager.expects(:move_packages)
          packager.expects(:cleanup_tmpdirs)
          packager.create_packages
        end

        it 'should clean up tmpdirs if keep_artifacts is false' do
          packager.stubs(:puts)
          Dir.stubs(:mktmpdir).raises('error')
          packager.expects(:cleanup_tmpdirs)
          expect{
            packager.create_packages
          }.to raise_error('error')
        end

        it 'should keep the build artifacts if keep_artifacts is true' do
          packager.instance_variable_set(:@keep_artifacts, true)
          packager.stubs(:puts)
          Dir.stubs(:mktmpdir).raises('error')
          packager.expects(:cleanup_tmpdirs).never
          expect{
            packager.create_packages
          }.to raise_error('error')
        end
      end

      describe '#create_debian_files' do
        it 'should create all the debian build files' do
          ['control', 'Makefile', 'compat', 'rules', 'copyright', 'changelog'].each do |f|
            packager.expects(:create_file).with(f)
          end
          packager.send(:create_debian_files)
        end
      end

      describe '#run_build' do
        it 'should build the packages' do
          FileUtils.expects(:cd).with('rspec_build').yields
          PluginPackager.stubs(:do_quietly).with(false).yields
          PluginPackager.expects(:safe_system).with('debuild --no-lintian -i -us -uc')
          packager.send(:run_build)
        end

        it 'should build the package and sign it with the set signature' do
          packager.instance_variable_set(:@signature, '0x1234')
          FileUtils.expects(:cd).with('rspec_build').yields
          PluginPackager.stubs(:do_quietly).with(false).yields
          PluginPackager.expects(:safe_system).with('debuild --no-lintian -i -k0x1234')
          packager.send(:run_build)
        end


        it 'should sign with the exported gpg key' do
          packager.instance_variable_set(:@signature, true)
          FileUtils.expects(:cd).with('rspec_build').yields
          PluginPackager.stubs(:do_quietly).with(false).yields
          PluginPackager.expects(:safe_system).with('debuild --no-lintian -i')
          packager.send(:run_build)
        end
      end

      describe '#build_dependency_string' do
        it 'should create the correct dependency string' do
          result = packager.send(:build_dependency_string, data)
          result.should == 'dep1, dep2 (>=1.1), dep3 (>=1.1-2), mcollective-rspec-common (= ${binary:Version})'
        end
      end

      describe '#create_install_file' do
        it 'should create the .install file in the correct location' do
          file = mock
          file.expects(:puts).with('rspec_libdir/agent/file.rb rspec_libdir/agent')
          file.expects(:puts).with('rspec_libdir/agent/file.ddl rspec_libdir/agent')
          file.expects(:puts).with('rspec_libdir/application/file.rb rspec_libdir/application')
          File.expects(:open).with('rspec_build/debian/mcollective-rspec-agent.install', 'w').yields(file)
          packager.send(:create_install_file, :agent, data)
        end

        it 'should write a message and raise an error if we do not have permission' do
          File.expects(:open).with('rspec_build/debian/mcollective-rspec-agent.install', 'w').raises(Errno::EACCES)
          packager.expects(:puts).with("Could not create install file 'rspec_build/debian/mcollective-rspec-agent.install'. Permission denied")
          expect{
            packager.send(:create_install_file, :agent, data)
          }.to raise_error(Errno::EACCES)
        end

        it 'should write a message and raise an error if we cannot create the install file' do
          File.expects(:open).with('rspec_build/debian/mcollective-rspec-agent.install', 'w').raises('error')
          packager.expects(:puts).with("Could not create install file 'rspec_build/debian/mcollective-rspec-agent.install'.")
          expect{
            packager.send(:create_install_file, :agent, data)
          }.to raise_error('error')
        end
      end

      describe '#move_packages' do
        it 'should move the source package and debs to the cdw' do
          files = ['rspec.deb', 'rspec.diff.gz', 'rspec.orig.tar.gz', 'rspec.changes']
          Dir.stubs(:glob).returns(files)
          FileUtils.expects(:cp).with(files, '.')
          packager.send(:move_packages)
        end

        it 'should log an error and raise an error if the files cannot be moved' do
          files = ['rspec.deb', 'rspec.diff.gz', 'rspec.orig.tar.gz', 'rspec.changes']
          Dir.stubs(:glob).returns(files)
          FileUtils.expects(:cp).with(files, '.').raises('error')
          packager.expects(:puts).with('Could not copy packages to working directory.')
          expect{
            packager.send(:move_packages)
          }.to raise_error('error')
        end
      end

      describe '#create_pre_and_post_install' do
        it 'should create the pre-install file' do
          plugin.stubs(:preinstall).returns('rspec-preinstall')
          plugin.stubs(:postinstall).returns(nil)
          File.expects(:exists?).with('rspec-preinstall').returns(true)
          FileUtils.expects(:cp).with('rspec-preinstall', 'rspec_build/debian/mcollective-rspec-agent.preinst')
          packager.send(:create_pre_and_post_install, :agent)
        end

        it 'should create the post-install file' do
          plugin.stubs(:preinstall).returns(nil)
          plugin.stubs(:postinstall).returns('rspec-postinstall')
          File.expects(:exists?).with('rspec-postinstall').returns(true)
          FileUtils.expects(:cp).with('rspec-postinstall', 'rspec_build/debian/mcollective-rspec-agent.postinst')
          packager.send(:create_pre_and_post_install, :agent)
        end

        it 'should fail if a pre-install script is defined but the file does not exist' do
          plugin.stubs(:preinstall).returns('rspec-preinstall')
          File.expects(:exists?).with('rspec-preinstall').returns(false)
          packager.expects(:puts).with("pre-install script 'rspec-preinstall' not found.")
          expect{
            packager.send(:create_pre_and_post_install, :agent)
         }.to raise_error(Errno::ENOENT, 'No such file or directory - rspec-preinstall')
        end

        it 'should fail if a post-install script is defined but the file does not exist' do
          plugin.stubs(:preinstall).returns(nil)
          plugin.stubs(:postinstall).returns('rspec-postinstall')
          File.expects(:exists?).with('rspec-postinstall').returns(false)
          packager.expects(:puts).with("post-install script 'rspec-postinstall' not found.")
          expect{
            packager.send(:create_pre_and_post_install, :agent)
         }.to raise_error(Errno::ENOENT, 'No such file or directory - rspec-postinstall')
        end
      end

      describe '#create_tar' do
        it 'should create the tarball' do
          PluginPackager.stubs(:do_quietly?).yields
          Dir.stubs(:chdir).with('rspec_tmp').yields
          PluginPackager.expects(:safe_system).with('tar -Pcvzf rspec_tmp/mcollective-rspec_1.0.orig.tar.gz mcollective-rspec_1.0')
          packager.send(:create_tar)
        end

        it 'should log an error and raise an exception if it cannot create the tarball' do
          PluginPackager.stubs(:do_quietly?).yields
          Dir.stubs(:chdir).with('rspec_tmp').yields
          PluginPackager.expects(:safe_system).raises('error')
          packager.expects(:puts).with("Could not create tarball - mcollective-rspec_1.0.orig.tar.gz")
          expect{
            packager.send(:create_tar)
          }.to raise_error('error')
        end
      end

      describe '#create_file' do
        it 'should create the named file in the build dir' do
          file = mock
          erb_content = mock
          File.stubs(:read).returns('<%= "file content" %>')
          ERB.expects(:new).with('<%= "file content" %>', nil, '-').returns(erb_content)
          File.stubs(:open).with('rspec_build/debian/rspec', 'w').yields(file)
          erb_content.expects(:result).returns('file content')
          file.expects(:puts).with('file content')
          packager.send(:create_file, 'rspec')
        end

        it 'should log an error and raise if it cannot create the file' do
          File.stubs(:read).returns('<%= "file content" %>')
          ERB.stubs(:new).with('<%= "file content" %>', nil, '-').raises('error')
          packager.expects(:puts).with("Could not create file - 'rspec'")
          expect{
            packager.send(:create_file, 'rspec')
          }.to raise_error('error')
        end
      end

      describe '#prepare_tmpdirs' do
        it 'should create the target directories and copy the files' do
          FileUtils.expects(:mkdir_p).with('rspec_build/rspec_libdir/agent').twice
          FileUtils.expects(:mkdir_p).with('rspec_build/rspec_libdir/application')
          FileUtils.expects(:cp_r).with('/rspec/agent/file.rb', 'rspec_build/rspec_libdir/agent')
          FileUtils.expects(:cp_r).with('/rspec/agent/file.ddl', 'rspec_build/rspec_libdir/agent')
          FileUtils.expects(:cp_r).with('/rspec/application/file.rb', 'rspec_build/rspec_libdir/application')
          packager.send(:prepare_tmpdirs, data)
        end

        it 'should log an error and raise if permissions means the dir cannot be created' do
          FileUtils.stubs(:mkdir_p).with('rspec_build/rspec_libdir/agent').raises(Errno::EACCES)
          packager.expects(:puts).with("Could not create directory 'rspec_build/rspec_libdir/agent'. Permission denied")
          expect{
            packager.send(:prepare_tmpdirs, data)
          }.to raise_error(Errno::EACCES)
        end

        it 'should log an error and raise if the file does not exist' do
          FileUtils.stubs(:mkdir_p)
          FileUtils.expects(:cp_r).with('/rspec/agent/file.rb', 'rspec_build/rspec_libdir/agent').raises(Errno::ENOENT)
          packager.expects(:puts).with("Could not copy file '/rspec/agent/file.rb' to 'rspec_build/rspec_libdir/agent'. File does not exist")
          expect{
            packager.send(:prepare_tmpdirs, data)
          }.to raise_error(Errno::ENOENT)
        end

        it 'should log an error and raise for any other exception' do
          File.stubs(:expand_path).raises('error')
          packager.expects(:puts).with('Could not prepare build directory')
          expect{
            packager.send(:prepare_tmpdirs, data)
          }.to raise_error('error')
        end
      end

      describe '#create_debian_dir' do
        it 'should create the debian dir in the build dir' do
          FileUtils.expects(:mkdir_p).with('rspec_build/debian')
          packager.send(:create_debian_dir)
        end

        it 'should log an error and raise an exception if the dir cannot be created' do
          FileUtils.expects(:mkdir_p).with('rspec_build/debian').raises('error')
          packager.expects(:puts).with("Could not create directory 'rspec_build/debian'")
          expect{
            packager.send(:create_debian_dir)
          }.to raise_error('error')
        end
      end

      describe '#cleanup_tmpdirs' do
        it 'should remove the temporary build directory' do
          File.stubs(:directory?).with('rspec_tmp').returns(true)
          FileUtils.expects(:rm_r).with('rspec_tmp')
          packager.send(:cleanup_tmpdirs)
        end

        it 'should log an error and raise an exception if the directory could not be removed' do
          File.stubs(:directory?).with('rspec_tmp').returns(true)
          FileUtils.expects(:rm_r).with('rspec_tmp').raises('error')
          packager.expects(:puts).with("Could not remove temporary build directory - 'rspec_tmp'")
          expect{
            packager.send(:cleanup_tmpdirs)
          }.to raise_error('error')
        end
      end
    end
  end
end
