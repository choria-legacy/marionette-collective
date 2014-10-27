RAKE_ROOT = File.expand_path(File.dirname(__FILE__))

# Allow override of RELEASE using BUILD_NUMBER
ENV["RELEASE"] = ENV["BUILD_NUMBER"] if ENV["BUILD_NUMBER"]

begin
  load File.join(RAKE_ROOT, 'ext', 'packaging.rake')
rescue LoadError
end

def announce(msg='')
  STDERR.puts "================"
  STDERR.puts msg
  STDERR.puts "================"
end

def safe_system *args
  raise RuntimeError, "Failed: #{args.join(' ')}" unless system(*args)
end

def load_tools
  unless File.directory?(File.join(RAKE_ROOT, 'ext', 'packaging'))
    Rake::Task["package:bootstrap"].invoke
    begin
      load File.join(RAKE_ROOT, 'ext', 'packaging.rake')
    rescue LoadError
      STDERR.puts "Could not load packaging tools. exiting"
      exit 1
    end
  end
end

def move_artifacts
  mv("pkg", "build")
end

desc "Cleanup"
task :clean do
  rm_rf "build"
  rm_rf "doc"
end

desc "Create the .debs"
task :deb => :clean do
  load_tools
  announce("Building debian packages for #{@build.project}-#{@build.version}-#{@build.release}")
  Rake::Task["package:deb"].invoke

  if ENV['SIGNED'] == '1'
    deb_flag = "-k#{ENV['SIGNWITH']}" if ENV['SIGNWITH']
    safe_system %{/usr/bin/debsign #{deb_flag} pkg/deb/*.changes}
  end
  move_artifacts
end

desc "Build documentation"
task :doc => :clean do
  load_tools
  Rake::Task["package:doc"].invoke
end

desc "Build a gem"
task :gem => :clean do
  load_tools
  Rake::Task["gem"].reenable
  Rake::Task["package:gem"].invoke
end

desc "Create a tarball for this release"
task :package => :clean do
  load_tools
  announce "Creating #{@build.project}-#{@build.version}.tar.gz"
  Rake::Task["package:tar"].invoke
  move_artifacts
end

desc "Creates a RPM"
task :rpm => :clean do
  load_tools
  announce("Building RPM for #{@build.project}-#{@build.version}-#{@build.release}")
  Rake::Task["package:rpm"].invoke
  Rake::Task["package:srpm"].invoke
  if ENV['SIGNED'] == '1'
    safe_system %{/usr/bin/rpm --sign pkg/**/*.rpm}
  end
  move_artifacts
end

desc "Run spec tests"
task :test do
  sh "cd spec && rake"
end

desc "Creates the website as a tarball"
task :website => :clean do
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

desc 'run static analysis with rubocop'
task(:rubocop) do
  if RUBY_VERSION !~ /1.8/
    require 'rubocop'
    cli = RuboCop::CLI.new
    cli.run(%w(-D -f s))
  else
    puts "Rubocop is disabled in ruby 1.8"
  end
end
