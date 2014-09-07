require 'json'
require 'singleton'

module MCollective
  class InstallOptions
    include Singleton

    attr_reader :configdir, :plugindir

    def initialize
      config_file = File.expand_path('../install_options.json', __FILE__)
      if File.readable?(config_file)
        config = JSON.parse(File.read(config_file))
      else
        config = default_options
      end

      @configdir = config['configdir']
      @plugindir = config['plugindir']
    end

    def default_options
      {
        'configdir' => '/etc/mcollective',
        'plugindir' => '/usr/libexec/mcollective'
      }
    end
  end
end
