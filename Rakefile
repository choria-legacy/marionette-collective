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
