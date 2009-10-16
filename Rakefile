require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = 'uri-meta'
    gem.summary     = 'Meta information for a URI'
    gem.description = 'Retrieves meta information for a URI from the meturi.com service.'
    gem.email       = 'production@statelesssystems.com'
    gem.homepage    = 'http://www.metauri.com/'
    gem.authors     = ['Stateless Systems']

    gem.add_dependency 'curb',   '>= 0.5.4'
    gem.add_dependency 'moneta', '>= 0.6.0'

    gem.add_development_dependency 'shoulda',   '>= 2.10.2'
    gem.add_development_dependency 'gemcutter', '>= 0.1.5'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler'
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort 'RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov'
  end
end

task :test    => :check_dependencies
task :default => :test
