require 'optparse'
require 'ruby_correct/yard_ext'

module RubyCorrect
  def self.root_path(*paths)
    File.join(File.dirname(__FILE__), '..', *paths)
  end

  def self.data_path(*paths)
    root_path('data', *paths)
  end

  def self.example_path(*paths)
    root_path('examples', *paths)
  end
end
