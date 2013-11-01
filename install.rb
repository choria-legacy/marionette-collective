#! /usr/bin/env ruby
#--
# Copyright 2004 Austin Ziegler <ruby-install@halostatue.ca>
#   Install utility. Based on the original installation script for rdoc by the
#   Pragmatic Programmers.
#
# This program is free software. It may be redistributed and/or modified under
# the terms of the GPL version 2 (or later) or the Ruby licence.
#
# Usage
# -----
# In most cases, if you have a typical project layout, you will need to do
# absolutely nothing to make this work for you. This layout is:
#
#   bin/    # executable files -- "commands"
#   lib/    # the source of the library
#
# The default behaviour:
# 1) Build Rdoc documentation from all files in bin/ (excluding .bat and .cmd),
#    all .rb files in lib/, ./README, ./ChangeLog, and ./Install.
#    and all .rb files in lib/.
# 2) Install configuration files in etc/.
# 3) Install commands from bin/ into the Ruby bin directory.
# 4) Install system commands from bin/ into the Ruby sbin directory.
# 5) Install all library files from lib/ into Ruby's site_lib/version
#    directory.
# 6) Install all plugins from plugins/ into the plugins directory
#    (usually $libexecdir/mcollective).
#
#++

require 'rbconfig'
require 'find'
require 'fileutils'
require 'tempfile'
require 'optparse'
require 'ostruct'
include FileUtils

begin
  require 'rdoc/rdoc'
  $haverdoc = true
rescue LoadError
  puts "Missing rdoc; skipping documentation"
  $haverdoc = false
end

if (defined?(RbConfig) ? RbConfig : Config)::CONFIG['host_os'] =~ /mswin|win32|dos|mingw|cygwin/i
    $stderr.puts "install.rb does not support Microsoft Windows. See ext/windows/README.md for information on installing on Microsoft Windows."
    exit(-1)
end

PREREQS = %w{rubygems stomp}

InstallOptions = OpenStruct.new

def glob(list)
  g = list.map { |i| Dir.glob(i) }
  g.flatten!
  g.compact!
  g.uniq!
  g
end

def check_prereqs
  PREREQS.each do |pre|
    begin
      require pre
    rescue LoadError
      puts "Could not load #{pre} Ruby library; cannot install"
      exit(-1)
    end
  end
end

def do_configs(configs, target, strip = 'etc/')
  Dir.mkdir(target) unless File.directory? target
  configs.each do |cf|
    ocf = File.join(target, cf.gsub(Regexp.new(strip), ''))
    oc = File.dirname(ocf)
    makedirs(oc, {:mode => 0755, :verbose => true})
    install(cf, ocf, {:mode => 0644, :preserve => true, :verbose => true})
  end
end

def do_bins(bins, target, strip = 's?bin/')
  Dir.mkdir(target) unless File.directory? target
  bins.each do |bf|
    obf = bf.gsub(/#{strip}/, '')
    install_binfile(bf, obf, target)
  end
end

def do_libs(libs, target, strip = 'lib/')
  libs.each do |lf|
    olf = File.join(target, lf.sub(/^#{strip}/, ''))
    op = File.dirname(olf)
    if File.directory?(lf)
      makedirs(olf, {:mode => 0755, :verbose => true})
    else
      makedirs(op, {:mode => 0755, :verbose => true})
      install(lf, olf, {:mode => 0644, :preserve => true, :verbose => true})
    end
  end
end

##
# Prepare the file installation.
#
def prepare_installation
  InstallOptions.configs = true

  # Only try to do docs if we're sure they have rdoc
  if $haverdoc
    InstallOptions.rdoc = true
  else
    InstallOptions.rdoc = false
  end


  ARGV.options do |opts|
    opts.banner = "Usage: #{File.basename($0)} [options]"
    opts.separator ""
    opts.on('--[no-]rdoc', 'Creation of RDoc output.', 'Default is create rdoc.') do |onrdoc|
      InstallOptions.rdoc = onrdoc
    end
    opts.on('--[no-]configs', 'Installation of config files', 'Default is install configs.') do |onconfigs|
      InstallOptions.configs = onconfigs
    end
    opts.on('--destdir[=OPTIONAL]', 'Installation prefix for all targets', 'Default essentially /') do |destdir|
      InstallOptions.destdir = destdir
    end
    opts.on('--configdir[=OPTIONAL]', 'Installation directory for config files', 'Default /etc/mcollective') do |configdir|
      InstallOptions.configdir = configdir
    end
    opts.on('--bindir[=OPTIONAL]', 'Installation directory for binaries', 'overrides RbConfig::CONFIG["bindir"]') do |bindir|
      InstallOptions.bindir = bindir
    end
    opts.on('--sbindir[=OPTIONAL]', 'Installation directory for system binaries', 'overrides RbConfig::CONFIG["sbindir"]') do |sbindir|
      InstallOptions.sbindir = sbindir
    end
    opts.on('--ruby[=OPTIONAL]', 'Ruby interpreter to use with installation', 'overrides ruby used to call install.rb') do |ruby|
      InstallOptions.ruby = ruby
    end
    opts.on('--sitelibdir[=OPTIONAL]', 'Installation directory for libraries', 'overrides RbConfig::CONFIG["sitelibdir"]') do |sitelibdir|
      InstallOptions.sitelibdir = sitelibdir
    end
    opts.on('--plugindir[=OPTIONAL]', 'Installation directory for plugins', 'Default /usr/libexec/mcollective') do |plugindir|
      InstallOptions.plugindir = plugindir
    end
    opts.on('--quick', 'Performs a quick installation. Only the', 'installation is done.') do |quick|
      InstallOptions.rdoc    = false
      InstallOptions.ri      = false
      InstallOptions.configs = true
    end
    opts.on('--full', 'Performs a full installation. All', 'optional installation steps are run.') do |full|
      InstallOptions.rdoc    = true
      InstallOptions.ri      = true
      InstallOptions.configs = true
    end
    opts.separator("")
    opts.on_tail('--help', "Shows this help text.") do
      $stderr.puts opts
      exit
    end

    opts.parse!
  end

  version = [RbConfig::CONFIG["MAJOR"], RbConfig::CONFIG["MINOR"]].join(".")
  libdir = File.join(RbConfig::CONFIG["libdir"], "ruby", version)

  # Mac OS X 10.5 and higher declare bindir
  # /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin
  # which is not generally where people expect executables to be installed
  # These settings are appropriate defaults for all OS X versions.
  if RUBY_PLATFORM =~ /^universal-darwin[\d\.]+$/
    RbConfig::CONFIG['bindir'] = "/usr/bin"
    RbConfig::CONFIG['sbindir'] = "/usr/sbin"
  end

  if InstallOptions.configdir
    configdir = InstallOptions.configdir
  else
    configdir = "/etc/mcollective"
  end

  if InstallOptions.bindir
    bindir = InstallOptions.bindir
  else
    bindir = RbConfig::CONFIG['bindir']
  end

  if InstallOptions.sbindir
    sbindir = InstallOptions.sbindir
  else
    sbindir = RbConfig::CONFIG['sbindir']
  end

  if InstallOptions.sitelibdir
    sitelibdir = InstallOptions.sitelibdir
  else
    sitelibdir = RbConfig::CONFIG["sitelibdir"]
    if sitelibdir.nil?
      sitelibdir = $LOAD_PATH.find { |x| x =~ /site_ruby/ }
      if sitelibdir.nil?
        sitelibdir = File.join(libdir, "site_ruby")
      elsif sitelibdir !~ Regexp.quote(version)
        sitelibdir = File.join(sitelibdir, version)
      end
    end
  end

  if InstallOptions.plugindir
    plugindir = InstallOptions.plugindir
  else
    plugindir = "/usr/libexec/mcollective"
  end

  if InstallOptions.destdir
    destdir = InstallOptions.destdir
  else
    destdir = ''
  end

  configdir   = File.join(destdir, configdir)
  bindir      = File.join(destdir, bindir)
  sbindir     = File.join(destdir, sbindir)
  sitelibdir  = File.join(destdir, sitelibdir)
  plugindir   = File.join(destdir, plugindir)

  makedirs(configdir) if InstallOptions.configs
  makedirs(bindir)
  makedirs(sbindir)
  makedirs(sitelibdir)
  makedirs(plugindir)

  InstallOptions.sitelibdir = sitelibdir
  InstallOptions.configdir = configdir
  InstallOptions.bindir  = bindir
  InstallOptions.sbindir  = sbindir
  InstallOptions.plugindir  = plugindir
end

##
# Build the rdoc documentation.
#
def build_rdoc(files)
  return unless $haverdoc
  begin
    r = RDoc::RDoc.new
    r.document(["--main", "MCollective", "--line-numbers"] + files)
  rescue RDoc::RDocError => e
    $stderr.puts e.message
  rescue Exception => e
    $stderr.puts "Couldn't build RDoc documentation\n#{e.message}"
  end
end

##
# Install file(s) from ./bin to RbConfig::CONFIG['bindir']. Patch it on the way
# to insert a #! line; on a Unix install, the command is named as expected
def install_binfile(from, op_file, target)
  tmp_file = Tempfile.new('mcollective-binfile')

  if InstallOptions.ruby
    ruby = InstallOptions.ruby
  else
    ruby = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
  end

  File.open(from) do |ip|
    File.open(tmp_file.path, "w") do |op|
      op.puts "#!#{ruby}"
      contents = ip.readlines
      contents.shift if contents[0] =~ /^#!/
      op.write contents.join
    end
  end

  install(tmp_file.path, File.join(target, op_file), :mode => 0755, :preserve => true, :verbose => true)
  tmp_file.unlink
end

# Change directory into the mcollective root so we don't get the wrong files for install.
cd File.dirname(__FILE__) do
  # Set these values to what you want installed.
  configs = glob(%w{etc/*.dist})
  erbs = glob(%w{etc/*.erb})
  bins = glob(%w{bin/mco})
  sbins = glob(%w{bin/mcollectived bin/mc-call-agent})
  rdoc = glob(%w{bin/* lib/**/*.rb README* })
  libs = glob(%w{lib/**/*})
  plugins = glob(%w{plugins/**/*})

  check_prereqs
  prepare_installation

  build_rdoc(rdoc) if InstallOptions.rdoc
  do_configs(configs, InstallOptions.configdir, 'etc/|\.dist') if InstallOptions.configs
  do_configs(erbs, InstallOptions.configdir) if InstallOptions.configs
  do_bins(bins, InstallOptions.bindir)
  do_bins(sbins, InstallOptions.sbindir)
  do_libs(libs, InstallOptions.sitelibdir)
  do_libs(plugins, InstallOptions.plugindir, 'plugins/')
end
