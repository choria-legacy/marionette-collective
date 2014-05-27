#!/usr/bin/env rspec

require 'spec_helper'


module MCollective
  describe InstallOptions do
    after do
      Singleton.__init__(InstallOptions)
    end
    context "when the install_options.json does not exist" do
      it "should return the pre-defined options" do
        File.stubs(:readable?).returns(false)
        Singleton.__init__(InstallOptions)
        expect(InstallOptions.instance.configdir).to eq '/etc/mcollective'
        expect(InstallOptions.instance.plugindir).to eq '/usr/libexec/mcollective'
      end
    end

    context "when the install_options.json exists" do
      it "should return the custom config options" do
        File.stubs(:readable?).returns(true)
        File.stubs(:read).returns({'configdir' => '/some/path', 'plugindir' => '/other/path'}.to_json)
        Singleton.__init__(InstallOptions)
        expect(InstallOptions.instance.configdir).to eq '/some/path'
        expect(InstallOptions.instance.plugindir).to eq '/other/path'
      end
    end
  end
end
