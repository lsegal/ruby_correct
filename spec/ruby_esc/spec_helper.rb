$:.unshift("/Users/#{ENV['USER']}/Development/Ruby/yard/lib")

require 'rspec'
require 'ruby_correct/cli/command'
require 'ruby_correct/ruby2boogie'
require 'ruby_correct/ruby2boogie/boogie/results'
require 'ruby_correct/ruby2boogie/boogie/output'
require 'ruby_correct/ruby_esc'

module Kernel
  def wrap(str = nil, &block)
    oldwrap = @wrap
    @wrap = str ? str : "${yield}"
    yield
    @wrap = oldwrap
  end

  def valid(str, result_text = "Success.")
    wrap = @wrap
    it("should be valid (L#{caller.first[/:(\d+)/,1]})") do
      output, result = "", nil
      cli = RubyCorrect::RubyEsc::CLI.new
      cli.options.verbose = true
      cli.stub(:puts) {|arg| output << arg }
      cli.stub(:exit) {|err| result = err }
      lambda do
        cli.run_with_source(wrap ? wrap.gsub("${yield}", str) : str)
      end.should_not raise_error
      output.should include(result_text)
      result.should == 0
    end
  end

  def invalid(str, result_text = nil)
    wrap = @wrap
    it("should be invalid (L#{caller.first[/:(\d+)/,1]})") do
      output, result = "", nil
      cli = RubyCorrect::RubyEsc::CLI.new
      cli.options.verbose = true
      cli.stub(:puts) {|arg| output << arg }
      cli.stub(:exit) {|err| result = err }
      begin
        cli.run_with_source(wrap ? wrap.gsub("${yield}", str) : str)
      rescue => e
      end
      output.should_not include("Success.")
      output.should include(result_text) if result_text
      result.should_not == 0
    end
  end

  def ex(filename)
    File.read(RubyCorrect.example_path('ruby_esc', filename + '.rb'))
  end
end