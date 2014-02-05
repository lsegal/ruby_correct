$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'tempfile'
require 'benchmark'
require 'ruby_correct'
require 'ruby_correct/ruby2boogie'
require 'ruby_correct/ruby2boogie/boogie/ast/program'
require 'ruby_correct/ruby2boogie/boogie/output'
require 'ruby_correct/ruby2boogie/boogie/results'

include RubyCorrect
$LATEX = ARGV.include?('--latex')

def report(file, loc, annot, cas, fail, inv, time)
  args = [file, loc.to_s, annot.to_s, cas.to_s, fail.to_s, inv.to_s, time.to_s]
  if $LATEX
    args[0].gsub!('_', '\_')
    puts("%-20s & %5s & %5s & %5s & %5s & %5s & %6s \\\\" % args)
  else
    puts("%20s %5s %5s %5s %5s %5s %6s" % args)
  end
end

report("FILE", "LOC", "ANNOT", "CASE", "FAIL", "INV", "TIME")
files = Dir['examples/ruby_case_gen/*.rb']
files.each do |exfile|
  lines = File.readlines(exfile)
  source = lines.join
  annot = lines.grep(/\A\s*#/).size
  loc = lines.grep(/\S/).size - annot
  
  run_time = Benchmark.measure do
#    RubyCorrect::RubyCaseGen::CLI.new.run(
  end
  
  report(File.basename(exfile), loc, annot, 0, 0, 0, ("%.2f" % run_time.real))
end

