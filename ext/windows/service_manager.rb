require 'optparse'

opt = OptionParser.new

ruby_path = ENV["RUBY"].gsub('"','')
basedir = ENV["BASEDIR"]
libdir = ENV["RUBYLIB"]
mcollectived = ENV["MCOLLECTIVED"]
configfile = ENV["SERVER_CONFIG"]

unless File.exist?(ruby_path)
  ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
    ruby = File.join(path, "ruby.exe")

    if File.exist?(ruby)
      ruby_path = ruby
      break
    end
  end
end

abort("Can't find ruby.ext in the path") unless ruby_path

options = {:name    => "mcollectived",
           :display_name => "The Marionette Collective",
           :description => "Puppet Labs server orchestration framework",
           :command => '%s -I"%s" -- "%s" --config "%s"' % [ ruby_path, libdir, mcollectived, configfile ]}

action = false

opt.on("--install", "Install service") do
  action = :install
end

opt.on("--uninstall", "Remove service") do
  action = :uninstall
end

opt.on("--name NAME", String, "Service name (#{options[:name]})") do |n|
  options[:name] = n
end

opt.on("--description DESCRIPTION", String, "Service description (#{options[:description]})") do |v|
  options[:description] = v
end

opt.on("--display NAME", String, "Service display name (#{options[:display_name]})") do |n|
  options[:display_name] = n
end

opt.on("--command COMMAND", String, "Service command (#{options[:command]})") do |c|
  options[:command] = c
end

opt.parse!

abort "Please choose an action with --install or --uninstall" unless action

require 'rubygems'
require 'win32/service'

include Win32

case action
  when :install
    if ENV["MC_STARTTYPE"] =~ /auto/i
      start_type = Service::AUTO_START
    else
      start_type = Service::DEMAND_START
    end

    Service.new(
      :service_name => options[:name],
      :display_name => options[:display_name],
      :description => options[:description],
      :binary_path_name => options[:command],
      :service_type => Service::SERVICE_WIN32_OWN_PROCESS,
      :start_type => start_type
    )

    puts "Service %s installed" % [options[:name]]

  when :uninstall
    Service.stop(options[:name]) unless Service.status(options[:name]).current_state == 'stopped'

    while Service.status(options[:name]).current_state != 'stopped'
      puts "Waiting for service %s to stop" % [options[:name]]
      sleep 1
    end

    Service.delete(options[:name])

    puts "Service %s removed" % [options[:name]]
end
