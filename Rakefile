require 'rspec'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ['-I', File.join(File.dirname(__FILE__), 'lib', 'ruby_correct')]
  t.verbose = false
end