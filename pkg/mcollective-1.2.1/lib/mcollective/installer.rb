require 'optparse'
require 'fileutils'

module MCollective
  class Installer
    # TODO: move to a central place
    DEFAULT_RUBY_PATH    = RbConfig::CONFIG['bindir'] rescue "/usr/bin/ruby"
    DEFAULT_CFG_PATH     = "/etc/mcollective"
    DEFAULT_PLUGINS_PATH = "/usr/libexec/mcollective"
    DEFAULT_BIN_PATH     = "/usr/sbin"
    INSTALLATION_TYPES = [:client,:server,:common,:full]
    
    def initialize(type = nil)
      @type    = type || :full
      @options = {
        :ruby_path    => DEFAULT_RUBY_PATH,
        :config_path  => DEFAULT_CFG_PATH,
        :plugins_path => DEFAULT_PLUGINS_PATH,
        :bin_path     => DEFAULT_BIN_PATH,
        :force        => false
      }
      parse!
    end
    
    def install!
      abort "Unknown installation type #{@type.inspect}" unless INSTALLATION_TYPES.include? @type
      send @type
    end
    
    private  
    def server
      FileUtils.mkdir_p @options[:config_path] + "/ssl" unless File.directory? @options[:config_path] + "/ssl"
      cp "mcollectived.rb",     "/usr/sbin/mcollectived"
      cp "mcollective.init-rh", "/etc/init.d/" if File.directory? "/etc/init.d" # TODO: on suse different init script
      cp "etc/facts.yaml.dist", "#{@options[:config_path]}/facts.yaml"
      cp "etc/server.cfg.dist", "#{@options[:config_path]}/server.cfg"
      cp "etc/rpc-help.erb",    "#{@options[:config_path]}/rpc-help.erb"
    end
    
    def client
      FileUtils.mkdir_p @options[:config_path] unless File.directory? @options[:config_path]
      cp "etc/client.cfg.dist","#{@options[:config_path]}/client.cfg"
      Dir.chdir base
      Dir.glob("{mc-*,mco}").each do |f| 
        dest = "#{@options[:bin_path]}/#{f}"
        cp f,dest
        FileUtils.chmod 0777,dest
      end
      
    end
    
    def common
      FileUtils.mkdir_p @options[:plugins_path] unless File.directory? @options[:plugins_path]
      FileUtils.cp_r "#{base}/plugins/mcollective", @options[:plugins_path]
    end
    
    define_method(:full) {[:server,:client,:common].each {|m| send m}}
    
    def parse!
      OptionParser.new do |opts|
        opts.banner = "Usage: mcollective_install"
        opts.separator ""
        opts.separator "Options:"
        opts.on("-r", "--ruby_path PATH", "default is #{@options[:ruby]}")  { |path| @options[:ruby_path]   = path }
        opts.on("-c", "--config_path PATH", "default is #{@options[:cfg]}") { |path| @options[:config_path] = path }
        opts.on("-f", "--force", "replace files, default is #{@options[:force]}") {  @options[:force]       = true }
      end.parse!
    end
    
    def base
      @base ||= File.expand_path(File.join(MCollective::ROOT,'..'))
    end
    
    def cp(src,dest)
      begin
        FileUtils.cp base + '/' + src,dest unless File.exists?(dest) && !@options[:force]
      rescue Errno::EACCES
        abort "Don't have write permissions #{dest}..."
      end
    end
    
  end # Installer
end # MCollective