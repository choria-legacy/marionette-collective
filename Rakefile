require 'packaging'
Pkg::Util::RakeUtils.load_packaging_tasks

# Allow override of RELEASE using BUILD_NUMBER
ENV["RELEASE"] = ENV["BUILD_NUMBER"] if ENV["BUILD_NUMBER"]

def announce(msg='')
  STDERR.puts "================"
  STDERR.puts msg
  STDERR.puts "================"
end

def safe_system *args
  raise RuntimeError, "Failed: #{args.join(' ')}" unless system(*args)
end

def move_artifacts
  mv("pkg", "build")
end

namespace :package do
  task :bootstrap do
    puts 'Bootstrap is no longer needed, using packaging-as-a-gem'
  end
  task :implode do
    puts 'Implode is no longer needed, using packaging-as-a-gem'
  end
end

desc "Cleanup"
task :clean do
  rm_rf "build"
  rm_rf "doc"
end

desc "Build documentation"
task :doc => :clean do
  Rake::Task["package:doc"].invoke
end

desc "Build a gem"
task :gem => :clean do
  Rake::Task["gem"].reenable
  Rake::Task["package:gem"].invoke
end

desc "Create a tarball for this release"
task :package => :clean do
  announce "Creating #{Pkg::Config.project}-#{Pkg::Config.version}.tar.gz"
  Rake::Task["package:tar"].invoke
  move_artifacts
end

desc "Run spec tests"
task :test do
  sh "cd spec && rake"
end

desc "Run spec tests"
task :test => :spec

namespace :ci do
  desc "Run the specs with CI options"
  task :spec do
    ENV["LOG_SPEC_ORDER"] = "true"
    sh %{rspec -r yarjuf -f JUnit -o result.xml -fp spec}
  end
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
    exit cli.run(%w(-D -f s))
  else
    puts "Rubocop is disabled in ruby 1.8"
  end
end
