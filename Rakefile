# Rakefile to build a project using HUDSON
RAKE_ROOT = File.expand_path(File.dirname(__FILE__))

begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
end

require 'rake/packagetask'
require 'rake/clean'
require 'find'
require 'rubygems/package_task'

PROJ_DOC_TITLE = "The Marionette Collective"
PROJ_VERSION = "2.3.2"
PROJ_RELEASE = "1"
PROJ_NAME = "mcollective"
PROJ_RPM_NAMES = [PROJ_NAME]
PROJ_FILES = ["#{PROJ_NAME}.init", "COPYING", "doc", "etc", "lib", "plugins", "ext", "bin"]
PROJ_FILES.concat(Dir.glob("mc-*"))
RDOC_EXCLUDES = ["mcollective/vendor", "spec", "ext", "website", "plugins"]

ENV["RPM_VERSION"] ? CURRENT_VERSION = ENV["RPM_VERSION"] : CURRENT_VERSION = PROJ_VERSION
ENV["BUILD_NUMBER"] ? CURRENT_RELEASE = ENV["BUILD_NUMBER"] : CURRENT_RELEASE = PROJ_RELEASE
ENV["DEB_DISTRIBUTION"] ? PKG_DEB_DISTRIBUTION = ENV["DEB_DISTRIBUTION"] : PKG_DEB_DISTRIBUTION = "unstable"

CLEAN.include(["build", "doc"])

begin
  load File.join(RAKE_ROOT, 'ext', 'packaging.rake')
rescue LoadError
end

def announce(msg='')
  STDERR.puts "================"
  STDERR.puts msg
  STDERR.puts "================"
end

def init
  FileUtils.mkdir("build") unless File.exist?("build")
end

def safe_system *args
  raise RuntimeError, "Failed: #{args.join(' ')}" unless system(*args)
end

spec = Gem::Specification.new do |s|
  s.name = "mcollective-client"
  s.version = PROJ_VERSION
  s.author = "R.I.Pienaar"
  s.email = "rip@puppetlabs.com"
  s.homepage = "https://docs.puppetlabs.com/mcollective/"
  s.summary = "Client libraries for The Marionette Collective"
  s.description = "Client libraries for the mcollective Application Server"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["spec/**/*"].to_a
  s.has_rdoc = true
  s.executables = "mco"
  s.default_executable = "mco"
  s.add_dependency "systemu"
  s.add_dependency "json"
  s.add_dependency "stomp"
  s.add_dependency "i18n"

  excluded_files = ["bin/mcollectived", "lib/mcollective/runner.rb", "lib/mcollective/vendor/json", "lib/mcollective/vendor/systemu", "lib/mcollective/vendor/i18n", "lib/mcollective/vendor/load"]

  excluded_files.each do |file|
    s.files.delete_if {|f| f.match(/^#{file}/)}
  end
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
  pkg.package_dir = "build"
end

desc "Build documentation, tar balls and rpms"
task :default => [:clean, :doc, :package]

# task for building docs
rd = Rake::RDocTask.new(:doc) { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "#{PROJ_DOC_TITLE} version #{CURRENT_VERSION}"
  rdoc.options << '--line-numbers' << '--main' << 'MCollective'

  RDOC_EXCLUDES.each do |ext|
    rdoc.options << '--exclude' << ext
  end
}

desc "Run spec tests"
task :test do
  sh "cd spec && rake"
end

desc "Create a tarball for this release"
task :package => [:clean, :doc] do
  announce "Creating #{PROJ_NAME}-#{CURRENT_VERSION}.tgz"

  FileUtils.mkdir_p("build/#{PROJ_NAME}-#{CURRENT_VERSION}")
  safe_system("cp -R #{PROJ_FILES.join(' ')} build/#{PROJ_NAME}-#{CURRENT_VERSION}")

  announce "Setting MCollective.version to #{CURRENT_VERSION}"
  safe_system("cd build/#{PROJ_NAME}-#{CURRENT_VERSION}/lib && sed -i -e s/@DEVELOPMENT_VERSION@/#{CURRENT_VERSION}/ mcollective.rb")

  safe_system("cd build && tar --exclude .svn -cvzf #{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{PROJ_NAME}-#{CURRENT_VERSION}")
end

desc "Creates the website as a tarball"
task :website => [:clean] do
  FileUtils.mkdir_p("build/marionette-collective.org/html")

  Dir.chdir("website") do
    safe_system("jekyll ../build/marionette-collective.org/html")
  end

  unless File.exist?("build/marionette-collective.org/html/index.html")
    raise "Failed to build website"
  end

  Dir.chdir("build") do
    safe_system("tar -cvzf marionette-collective-org-#{Time.now.to_i}.tgz marionette-collective.org")
  end
end

desc "Creates a RPM"
task :rpm => [:clean, :doc, :package] do
  announce("Building RPM for #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}")

  sourcedir = `rpm --eval '%_sourcedir'`.chomp
  specsdir = `rpm --eval '%_specdir'`.chomp
  srpmsdir = `rpm --eval '%_srcrpmdir'`.chomp
  rpmdir = `rpm --eval '%_rpmdir'`.chomp
  lsbdistrel = `lsb_release -r -s | cut -d . -f1`.chomp
  lsbdistro = `lsb_release -i -s`.chomp

  `which rpmbuild-md5`
  rpmcmd = $?.success? ? 'rpmbuild-md5' : 'rpmbuild'

  case lsbdistro
  when 'CentOS'
    rpmdist = ".el#{lsbdistrel}"
  when 'Fedora'
    rpmdist = ".fc#{lsbdistrel}"
  else
    rpmdist = ""
  end

  safe_system %{cp build/#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{sourcedir}}
  safe_system %{cat ext/redhat/#{PROJ_NAME}.spec|sed -e s/%{rpm_release}/#{CURRENT_RELEASE}/g | sed -e s/%{version}/#{CURRENT_VERSION}/g > #{specsdir}/#{PROJ_NAME}.spec}

  if ENV['SIGNED'] == '1'
    safe_system %{#{rpmcmd} --sign -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist #{rpmdist}' -D 'use_lsb 0' -ba #{specsdir}/#{PROJ_NAME}.spec}
  else
    safe_system %{#{rpmcmd} -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist #{rpmdist}' -D 'use_lsb 0' -ba #{specsdir}/#{PROJ_NAME}.spec}
  end

  safe_system %{cp #{srpmsdir}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}#{rpmdist}.src.rpm build/}

  safe_system %{cp #{rpmdir}/*/#{PROJ_NAME}*-#{CURRENT_VERSION}-#{CURRENT_RELEASE}#{rpmdist}.*.rpm build/}
end

desc "Create the .debs"
task :deb => [:clean, :doc, :package] do
  announce("Building debian packages")

  FileUtils.mkdir_p("build/deb")
  Dir.chdir("build/deb") do
    safe_system %{tar -xzf ../#{PROJ_NAME}-#{CURRENT_VERSION}.tgz}
    safe_system %{cp ../#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{PROJ_NAME}_#{CURRENT_VERSION}.orig.tar.gz}

    Dir.chdir("#{PROJ_NAME}-#{CURRENT_VERSION}") do
      safe_system %{cp -R ext/debian .}
      safe_system %{cp -R ext/debian/mcollective.init .}

      File.open("debian/changelog", "w") do |f|
        f.puts("mcollective (#{CURRENT_VERSION}-#{CURRENT_RELEASE}) #{PKG_DEB_DISTRIBUTION}; urgency=low")
        f.puts
        f.puts("  * Automated release for #{CURRENT_VERSION}-#{CURRENT_RELEASE} by rake deb")
        f.puts
        f.puts("    See http://marionette-collective.org/releasenotes.html for full details")
        f.puts
        f.puts(" -- The Marionette Collective <mcollective-dev@googlegroups.com>  #{Time.new.strftime('%a, %d %b %Y %H:%M:%S %z')}")
      end

      if ENV['SIGNED'] == '1'
        if ENV['SIGNWITH']
          safe_system %{debuild -i -k#{ENV['SIGNWITH']}}
        else
          safe_system %{debuild -i}
        end
      else
        safe_system %{debuild -i -us -uc}
      end
    end

    safe_system %{cp *.deb *.dsc *.diff.gz *.orig.tar.gz *.changes ..}
  end
end

desc "Update the website error code reference based on current local"
task :update_msgweb do
  mcollective_dir = File.join(File.dirname(__FILE__))

  $:.insert(0, File.join(mcollective_dir, "lib"))

  require 'mcollective'

  messages = YAML.load_file(File.join(mcollective_dir, "lib", "mcollective", "locales", "en.yml"))

  webdir = File.join(mcollective_dir, "website", "messages")

  I18n.load_path = Dir[File.join(mcollective_dir, "lib", "mcollective", "locales", "*.yml")]
  I18n.locale = :en

  messages["en"].keys.each do |msg_code|
    md_file = File.join(webdir, "#{msg_code}.md")

    puts "....writing %s" % md_file

    File.open(md_file, "w") do |md|
      md.puts "---"
      md.puts "layout: default"
      md.puts "title: Message detail for %s" % msg_code
      md.puts "toc: false"
      md.puts "---"
      md.puts
      md.puts "Example Message"
      md.puts "---------------"
      md.puts
      md.puts "    %s" % (MCollective::Util.t("%s.example" % msg_code, :raise => true) rescue MCollective::Util.t("%s.pattern" % msg_code))
      md.puts
      md.puts "Additional Information"
      md.puts "----------------------"
      md.puts
      md.puts MCollective::Util.t("%s.expanded" % msg_code, :raise => true)
    end
  end
end
