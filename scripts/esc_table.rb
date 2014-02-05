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

def report(file, loc, annot, ver, err, eerr, ptime, rtime)
  args = [file, loc.to_s, annot.to_s, ver.to_s, err.to_s, eerr.to_s, ptime.to_s, rtime.to_s]
  if $LATEX
    args[0].gsub!('_', '\_')
    puts("%-20s & %5s & %5s & %5s & %5s & %5s & %6s & %6s \\\\\n\\hline" % args)
  else
    puts("%20s %5s %5s %5s %5s %5s %6s %6s" % args)
  end
end

report("FILE", "LOC", "ANNOT", "VERF", "ERR", "EERR", "PTIME", "RTIME")
files = Dir['examples/ruby_esc/*.rb']
files.each do |exfile|
  lines = File.readlines(exfile)
  source = lines.join
  annot = lines.grep(/\A\s*#/).size
  loc = lines.grep(/\S/).size - annot
  
  
  file = Tempfile.open(%w(boogie .bpl), Dir.pwd)
  base = File.basename(file.path)
  bpl = nil
  parse_time = Benchmark.measure do
    program = Ruby2Boogie::Converter.new.convert(source)
    bpl = Ruby2Boogie::Boogie::Output.new
    program.to_buf(bpl)
  end
  file.puts(bpl)
  file.flush
  cmd = "boogie /nologo #{base}"
  results = nil
  file.close
  run_time = Benchmark.measure { results = %x{#{cmd}} }
  psize = Ruby2Boogie::Converter.preamble.split("\n").size
  boogie_results = Ruby2Boogie::Boogie::Results.new(results, bpl.nodemap, psize + 2)
  if results =~ /finished with (\d+) verified, (\d+) error/
    verified, errors = $1, $2
  else
    verified = 0
    errors = boogie_results.errors.size
  end
  
  report(File.basename(exfile), loc, annot, verified, errors, errors, ("%.2f" % parse_time.real), ("%.2f" % run_time.real))
end

