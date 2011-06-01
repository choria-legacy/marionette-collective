# Rakefile to build a project using HUDSON

require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/clean'
require 'find'

PROJ_DOC_TITLE = "The Marionette Collective"
PROJ_VERSION = "1.2.0"
PROJ_RELEASE = "6"
PROJ_NAME = "mcollective"
PROJ_RPM_NAMES = [PROJ_NAME]
PROJ_FILES = ["#{PROJ_NAME}.spec", "#{PROJ_NAME}.init", "#{PROJ_NAME}.init-rh", "mcollectived.rb", "COPYING", "doc", "etc", "lib", "plugins", "ext", "mco"]
PROJ_FILES.concat(Dir.glob("mc-*"))

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

desc "Build documentation, tar balls and rpms"
task :default => [:clean, :doc, :package]

# task for building docs
rd = Rake::RDocTask.new(:doc) { |rdoc|
    rdoc.rdoc_dir = 'doc'
    rdoc.template = 'html'
    rdoc.title    = "#{PROJ_DOC_TITLE} version #{CURRENT_VERSION}"
    rdoc.options << '--line-numbers' << '--inline-source' << '--main' << 'MCollective' << '--exclude' << 'mcollective/vendor/'
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
    safe_system("cd build/#{PROJ_NAME}-#{CURRENT_VERSION}/lib && sed --in-place -e s/@DEVELOPMENT_VERSION@/#{CURRENT_VERSION}/ mcollective.rb")

    safe_system("cd build && tar --exclude .svn -cvzf #{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{PROJ_NAME}-#{CURRENT_VERSION}")
end

desc "Creates a dmg OS X Package using The Luggage"
task :dmg => [:clean, :doc] do
    announce "Creating #{PROJ_NAME}-#{CURRENT_VERSION}.dmg"

    raise "\n\n================\nTo create DMGs, rake must be run as root.  Exiting.\n================" unless Process.uid == 0

    unless File.exist?("/usr/local/share/luggage/examples/mcollective/Makefile")
      puts "\n\n================\n'/usr/local/share/luggage/examples/mcollective/Makefile' was not found."
      puts "Visit http://github.com/glarizza/luggage and clone to /usr/local/share.\n================"
      raise "Exiting."
    end 

    safe_system("cd /usr/local/share/luggage/examples/mcollective && make dmg PACKAGE_VERSION=#{PROJ_VERSION} TYPE=CLIENT")
    safe_system("cd /usr/local/share/luggage/examples/mcollective && make dmg PACKAGE_VERSION=#{PROJ_VERSION} TYPE=COMMON")
    safe_system("cd /usr/local/share/luggage/examples/mcollective && make dmg PACKAGE_VERSION=#{PROJ_VERSION} TYPE=BASE")
    safe_system("mv /usr/local/share/luggage/examples/mcollective/MCollective_* .")

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

    case lsbdistro
        when 'CentOS'
            rpmdist = ".el#{lsbdistrel}"
        else
            rpmdist = ""
    end

    safe_system %{cp build/#{PROJ_NAME}-#{CURRENT_VERSION}.tgz #{sourcedir}}
    safe_system %{cat #{PROJ_NAME}.spec|sed -e s/%{rpm_release}/#{CURRENT_RELEASE}/g | sed -e s/%{version}/#{CURRENT_VERSION}/g > #{specsdir}/#{PROJ_NAME}.spec}

    if ENV['SIGNED'] == '1'
        safe_system %{rpmbuild --sign -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist #{rpmdist}' -D 'use_lsb 0' -ba #{PROJ_NAME}.spec}
    else
        safe_system %{rpmbuild -D 'version #{CURRENT_VERSION}' -D 'rpm_release #{CURRENT_RELEASE}' -D 'dist #{rpmdist}' -D 'use_lsb 0' -ba #{PROJ_NAME}.spec}
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
                            safe_system %{debuild -i -b -k#{ENV['SIGNWITH']}}
                    else
                            safe_system %{debuild -i -b}
                    end
            else
                safe_system %{debuild -i -us -uc -b}
            end
        end

        safe_system %{cp *.deb *.changes ..}
    end

end

desc "Send patch information to the puppet-dev list"
task :mail_patches do
    if Dir.glob("00*.patch").length > 0
        raise "Patches already exist matching '00*.patch'; clean up first"
    end

    unless %x{git status} =~ /On branch (.+)/
        raise "Could not get branch from 'git status'"
    end
    branch = $1

    unless branch =~ %r{^([^\/]+)/([^\/]+)/([^\/]+)$}
        raise "Branch name does not follow <type>/<parent>/<name> model; cannot autodetect parent branch"
    end

    type, parent, name = $1, $2, $3

    # Create all of the patches
    sh "git format-patch -C -M -s -n --subject-prefix='PATCH/mcollective' #{parent}..HEAD"

    # Add info to the patches
    additional_info = "Local-branch: #{branch}\n"
    files = Dir.glob("00*.patch")
    files.each do |file|
        contents = File.read(file)
        contents.sub!(/^---\n/, "---\n#{additional_info}")
        File.open(file, 'w') do |file_handle|
            file_handle.print contents
        end
    end

    # And then mail them out.

    # If we've got more than one patch, add --compose
    if files.length > 1
        compose = "--compose"
        subject = "--subject \"#{type} #{name} against #{parent}\""
    else
        compose = ""
        subject = ""
    end

    # Now send the mail.
    sh "git send-email #{compose} #{subject} --no-signed-off-by-cc --suppress-from --to puppet-dev@googlegroups.com 00*.patch"

    # Finally, clean up the patches
    sh "rm 00*.patch"
end
# vi:tabstop=4:expandtab:ai
