# Rakefile to build a project using HUDSON

require 'rake/rdoctask'
require 'rake/clean'

PROJ_NAME = "mcollective"
PROJ_FILES = ["build/doc", "#{PROJ_NAME}.spec", "#{PROJ_NAME}.init", "mcollectived.rb", "etc", "lib", "plugins"]
PROJ_FILES << Dir.glob("mc-*")
PROJ_DOC_TITLE = "The Marionette Collective"
PROJ_VERSION = "0.1"
PROJ_RELEASE = "1"
PROJ_RPM_NAMES = [PROJ_NAME]

ENV["RPM_VERSION"] ? CURRENT_VERSION = ENV["RPM_VERSION"] : CURRENT_VERSION = PROJ_VERSION
ENV["BUILD_NUMBER"] ? CURRENT_RELEASE = ENV["BUILD_NUMBER"] : CURRENT_RELEASE = PROJ_RELEASE

CLEAN.include("build")

def announce(msg='')
  STDERR.puts "================"
  STDERR.puts msg
  STDERR.puts "================"
end

def init
    FileUtils.mkdir("build") unless File.exist?("build")
end

desc "Build documentation, tar balls and rpms"
task :default => [:clean, :doc, :archive, :rpm, :tag] do
end

# taks for building docs
rd = Rake::RDocTask.new(:doc) { |rdoc|
    announce "Building documentation for #{CURRENT_VERSION}"

    rdoc.rdoc_dir = 'build/doc'
    rdoc.template = 'html'
    rdoc.title    = "#{PROJ_DOC_TITLE} version #{CURRENT_VERSION}"
    rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'MCollective'
}

desc "Create a tarball for this release"
task :archive => [:clean, :doc] do
    announce "Creating #{PROJ_NAME}-#{CURRENT_VERSION}.tgz"

    FileUtils.mkdir_p("build/#{PROJ_NAME}-#{CURRENT_VERSION}")
    system("cp -R #{PROJ_FILES.join(' ')} build/#{PROJ_NAME}-#{CURRENT_VERSION}")
    system("cd build && /bin/tar --exclude .svn -cvzf #{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{PROJ_NAME}-#{CURRENT_VERSION}")
end

desc "Tag the release in SVN"
task :tag => [:rpm] do
    ENV["TAGS_URL"] ? TAGS_URL = ENV["TAGS_URL"] : TAGS_URL = `/usr/bin/svn info|/bin/awk '/Repository Root/ {print $3}'`.chomp + "/tags"

    raise("Need to specify a SVN url for tags using the TAGS_URL environment variable") unless TAGS_URL

    announce "Tagging the release for version #{CURRENT_VERSION}-#{CURRENT_RELEASE}"
    sh %{svn copy -m 'Hudson adding release tag #{CURRENT_VERSION}-#{CURRENT_RELEASE}' ../#{PROJ_NAME}/ #{TAGS_URL}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}}
end

desc "Creates a RPM"
task :rpm => [:archive] do
    announce("Building RPM for #{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}")

    sourcedir = `/bin/rpm --eval '%_sourcedir'`.chomp
    specsdir = `/bin/rpm --eval '%_specdir'`.chomp
    srpmsdir = `/bin/rpm --eval '%_srcrpmdir'`.chomp
    rpmdir = `/bin/rpm --eval '%_rpmdir'`.chomp
    lsbdistrel = `/usr/bin/lsb_release -r -s|/bin/cut -d . -f1`.chomp
    lsbdistro = `/usr/bin/lsb_release -i -s`.chomp

    case lsbdistro
        when 'CentOS'
            rpmdist = "el#{lsbdistrel}"
        else
            rpmdist = ""
    end

    sh %{cp build/#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{sourcedir}}
    sh %{cp #{PROJ_NAME}.spec #{specsdir}}

    sh %{cd #{specsdir} && rpmbuild -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist .#{rpmdist}' -ba #{PROJ_NAME}.spec}

    sh %{cp #{srpmsdir}/#{PROJ_NAME}-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.#{rpmdist}.src.rpm build/}

    sh %{cp #{rpmdir}/*/#{PROJ_NAME}*-#{CURRENT_VERSION}-#{CURRENT_RELEASE}.#{rpmdist}.*.rpm build/}
end

# vi:tabstop=4:expandtab:ai
