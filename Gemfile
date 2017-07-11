source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'stomp', '>= 1.4.4'
gem 'net-ssh'

if RUBY_VERSION =~ /^1\.8/
  gem 'systemu', '2.6.4'
  gem 'json', '~> 1.8.3'
else
  gem 'systemu'
end

if RUBY_VERSION =~ /^2\.4/
  gem 'json', '~> 2.1.0'
end

group :dev do
  gem 'rake', '~> 10.4'
  if RUBY_VERSION =~ /^2\.[0-9]\.[0-9]/
    gem 'rubocop', '~> 0.48.1', :platforms => [:ruby]
  end
end

group :test do
  if RUBY_VERSION =~ /^1\.8/
    gem 'rdoc', '~> 4.2.2'
  else
    gem 'rdoc'
  end
  gem 'yarjuf', "~> 1.0"
  gem 'rspec', '~> 2.11.0'
  gem 'mocha', '~> 0.10.0'
  gem 'mcollective-test'
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
