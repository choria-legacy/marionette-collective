require 'optparse'
require 'fileutils'

module MCollective
  class Installer
    # TODO: move to a central place
    DEFAULT_CFG_PATH     = "/etc/mcollective"
    DEFAULT_PLUGINS_PATH = "/usr/libexec/mcollective"
    DEFAULT_BIN_PATH     = "/usr/sbin"
    INSTALLATION_TYPES   = [:client,:server,:common,:full]
    
    def initialize
      @options = {
        :ruby_path    => nil,
        :config_path  => DEFAULT_CFG_PATH,
        :plugins_path => DEFAULT_PLUGINS_PATH,
        :bin_path     => DEFAULT_BIN_PATH,
        :force        => false,
        :custom_config_file => nil,
        :custom_facts_yaml  => nil
      }
      parse!
    end
    
    def install!
      abort "[ERROR] Unknown installation type #{@type.inspect}..." unless INSTALLATION_TYPES.include? @type
      send @type
    end
    
    private
    def server
      msg "Installing MCollective Server"
      FileUtils.mkdir_p @options[:config_path] + "/ssl" unless File.directory? @options[:config_path] + "/ssl"
      daemon_path = "/usr/sbin/mcollectived"
      unless File.exists?(daemon_path) && !@options[:force]
        cp "mcollectived.rb",daemon_path
        FileUtils.chmod 0777,daemon_path
      end
      
      # TODO: on suse/ubuntu different init script
      if File.directory? "/etc/init.d"
        cp "mcollective.init-rh", "/etc/init.d/mcollective"
        `sed -ie 's|rubycmd="ruby"|rubycmd="#{@options[:ruby_path]}"|' /etc/init.d/mcollective` if @options[:ruby_path]
        FileUtils.chmod 0777,"/etc/init.d/mcollective"
      end
      
      if @options[:custom_config_file]
        abort "Can't find the external config file #{@options[:custom_config_file]}" unless File.exists? @options[:custom_config_file]
        cp @options[:custom_config_file], "#{@options[:config_path]}/server.cfg"
      else
        cp "etc/server.cfg.dist", "#{@options[:config_path]}/server.cfg"
      end
      
      if @options[:custom_facts_yaml]
        abort "Can't find the external facts file #{@options[:custom_facts_yaml]}" unless File.exists? @options[:custom_facts_yaml]
        cp @options[:custom_facts_yaml], "#{@options[:config_path]}/facts.yaml"
      else
        cp "etc/facts.yaml.dist", "#{@options[:config_path]}/facts.yaml"
      end
      
      cp "etc/rpc-help.erb",    "#{@options[:config_path]}/rpc-help.erb"
    end
    
    def client
      msg "Installing MCollective Client"
      FileUtils.mkdir_p @options[:config_path] unless File.directory? @options[:config_path]
      cp "etc/client.cfg.dist","#{@options[:config_path]}/client.cfg"
      Dir.chdir base
      Dir.glob("{mc-*,mco}").each do |f| 
        cp f,"#{@options[:bin_path]}/#{f}"
        FileUtils.chmod 0777,"#{@options[:bin_path]}/#{f}"
      end
    end
    
    def common
      msg "Installing MCollective Common Plugins"
      FileUtils.mkdir_p @options[:plugins_path] unless File.directory? @options[:plugins_path]
      FileUtils.cp_r "#{base}/plugins/mcollective", @options[:plugins_path]
    end
    
    define_method(:full) {[:server,:client,:common].each {|m| send m}}
        
    def parse!
      OptionParser.new do |opts|
        opts.banner = "Usage: mcollective_install [options] #{INSTALLATION_TYPES.join ','} (default full)"
        opts.separator ""
        opts.separator "Options:"
        opts.on("-r",  "--ruby_path PATH","default is ruby")                         { |o| @options[:ruby_path]    = o }
        opts.on("-c",  "--config_path PATH","default is #{@options[:config_path]}")  { |o| @options[:config_path]  = o }
        opts.on("-p",  "--plugins_path PATH","default is #{@options[:plugins_path]}"){ |o| @options[:plugins_path] = o }
        opts.on("-b",  "--bin_path PATH","default is #{@options[:bin_path]}")        { |o| @options[:bin_path]     = o }
        opts.on("-C", "--custom_config_file PATH","e.g /etc/conf/my_server.cfg")    { |o| @options[:custom_config_file] = o }
        opts.on("-F", "--custom_facts_yaml PATH","e.g /etc/conf/my_facts.yaml")     { |o| @options[:custom_facts_yaml]  = o }
        opts.on("-f",  "--force","replace files, default is #{@options[:force]}")    { @options[:force] = true }
      end.parse!
      @type = (ARGV.shift || 'full').to_sym
    end
    
    def base
      @base ||= File.expand_path(File.join(MCollective::ROOT,'..'))
    end
    
    def cp(src,dest)
      begin
        file = File.exists?("#{base}/#{src}") ? "#{base}/#{src}" : src
        FileUtils.cp file,dest unless File.exists?(dest) && !@options[:force]
      rescue Errno::EACCES
        abort "[ERROR] Don't have write permissions #{dest}..."
      end
    end
    
    def msg m
      STDERR.puts "[*] #{m}..."
    end
    
  end # Installer
end # MCollective