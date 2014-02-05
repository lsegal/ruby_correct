require 'tempfile'
require 'benchmark'
require 'ruby_correct'

module RubyCorrect
  module RubyEsc
    class CLI < CLI::Command
      def description; 'Performs extended static checking on Ruby code' end

      def setup_options(opts)
        super
        opts.on('--dry', 'Dry run') { options.dry_run = true }
      end

      def run(*args)
        super(args)

        require 'ruby_correct/ruby2boogie'
        require 'ruby_correct/ruby2boogie/boogie/ast/program'
        require 'ruby_correct/ruby2boogie/boogie/output'
        require 'ruby_correct/ruby2boogie/boogie/results'

        source = args.map {|f| File.read(f) }.join("\n\n")
        run_with_source(source)
      end
      
      def run_with_source(source)
        file = Tempfile.open(%w(boogie .bpl), Dir.pwd)
        base = File.basename(file.path)
        bpl = nil
        time = Benchmark.measure do
          program = Ruby2Boogie::Converter.new.convert(source)
          bpl = Ruby2Boogie::Boogie::Output.new
          program.to_buf(bpl)
        end
        puts "====== Boogie Output (#{base}) (#{'%.2f' % time.real}s) ======\n\n#{bpl}" if options.verbose
        file.puts(bpl)
        file.flush
        unless options.dry_run
          cmd = "boogie /nologo #{base}"
          puts ">> Running: `#{cmd}'...\n\n" if options.verbose
          results = nil
          file.close
          time = Benchmark.measure { results = `#{cmd}` }
          if options.verbose
            puts "====== Boogie Results (#{'%.2f' % time.real}s) ======\n\n#{results}\n"
            puts "====== Results ======\n\n"
          end
          psize = Ruby2Boogie::Converter.preamble.split("\n").size
          boogie_results = Ruby2Boogie::Boogie::Results.new(results, bpl.nodemap, psize + 2)
          puts boogie_results.to_s
          exit boogie_results.errors.size
        end
      ensure
        if file
          file.close
          file.unlink
        end
      end
    end
  end
end
