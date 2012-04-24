# Rakefile to build a project using HUDSON

require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/clean'
require 'find'
require 'rake/gempackagetask'

PROJ_DOC_TITLE = "The Marionette Collective"
PROJ_VERSION = "1.3.3"
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

def announce(msg='')
  STDERR.puts "================"
  STDERR.puts msg
  STDERR.puts "================"
end

def init
  FileUtils.mkdir("build") unless File.exist?("build")
end

def safe_system *args
  raise RuntimeError, "Failed: #{args.join(' ')}" unless system *args
end

spec = Gem::Specification.new do |s|
  s.name = "mcollective-client"
  s.version = PROJ_VERSION
  s.author = "R.I.Pienaar"
  s.email = "rip@puppetlabs.com"
  s.homepage = "https://docs.puppetlabs.com/mcollective/"
  s.summary = "Client for The Marionette Collective"
  s.description = "Client tools for the mcollective Application Server"
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["spec/**/*"].to_a
  s.has_rdoc = true
  s.executables = "mco"
  s.default_executable = "mco"
  s.add_dependency "systemu"
  s.add_dependency "json"

  excluded_files = ["bin/mcollectived", "lib/mcollective/runner.rb", "lib/mcollective/vendor/json", "lib/mcollective/vendor/systemu", "lib/mcollective/vendor/load"]

  excluded_files.each do |file|
    s.files.delete_if {|f| f.match(/^#{file}/)}
  end
end

Rake::GemPackageTask.new(spec) do |pkg|
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
  rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'MCollective'

  RDOC_EXCLUDES.each do |ext|
    rdoc.options << '--exclude' << ext
  end
}

desc "Run spec tests"
task :test do
    sh "cd spec;rake"
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
      safe_system %{cp -R ext/Makefile .}

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
