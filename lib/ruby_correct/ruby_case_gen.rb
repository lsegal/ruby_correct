require 'rbconfig'
require 'rubygems'
require 'fileutils'
require 'yard'
require 'ruby_correct/cli/command'

module RubyCorrect
  module RubyCaseGen
    module Helpers
      def self.translate_type(type)
        type.gsub(/^java\.lang\./, '')
      end

      def self.value_for_type(type)
        case translate_type(type)
        when "String"; "''"
        when "HashMap"; "{}"
        when "Array"; "[]"
        else; "#{type}.new"
        end
      end

      def self.indent(data, n = 1)
        data.gsub(/\A/, ('  ' * n)).gsub(/\n/, "\n" + ('  ' * n))
      end
    end

    class CLI < CLI::Command
      def description; 'Generates unit tests for Ruby code' end

      def setup_options(opts)
        super
        options.use_cache = true
        options.errors_only = false
        opts.on('-errors-only', 'Only generate error cases') { options.errors_only = true }
        opts.on('--no-cache', 'Do not use cache') { options.use_cache = false }
      end

      def run(*args)
        load_jruby(*args)

        super(args)

        class_name = args[0]
        method_name = args[1]
        file_no_ext = RubyCorrect.example_path('ruby_case_gen', class_name)
        ruby_file = file_no_ext + '.rb'
        mirah_file = file_no_ext + '.mirah'
        class_file = file_no_ext + '.class'
        descriptor = args[2] || generate_descriptor(ruby_file, class_name, method_name)

        require 'java'
        require 'ruby_correct/ruby_case_gen/concrete_value_resolver'
        require 'ruby_correct/ruby_case_gen/test_generator'

        # Remove any previously generated files
        clear_cache(class_name) unless options.use_cache

        # Convert Ruby file to mirah
        convert_to_mirah(ruby_file) unless File.file?(mirah_file)
        return unless File.file?(mirah_file)

        # Compile Mirah code
        compile_class(class_name) unless File.file?(class_file)
        return unless File.file?(class_file)

        glob = RubyCorrect.root_path('xml', class_name, '*', '*-symcase.xml')

        # Run Kiasan
        run_kiasan(class_name, method_name, descriptor) unless Dir.glob(glob).size > 0

        # Run concrete resolvers on symbolic data
        test_cases = ConcreteValueResolver.new.resolve_reports(glob)

        # Generate tests
        YARD.parse([ruby_file])
        gen = TestGenerator.new(class_name, method_name)
        puts gen.generate_cases(test_cases, options.errors_only)

        exit
      end

      def load_jruby(*args)
        return if RUBY_PLATFORM == "java" && ENV['CLASSPATH'].include?("kiasan")
        sep = windows? ? ';' : ':'
        classpath = (ENV['CLASSPATH'] || '').split(sep)
        classpath |= [RubyCorrect.data_path('ruby_case_gen', 'kiasan.jar')]
        classpath |= [RubyCorrect.example_path('ruby_case_gen')]
        classpath |= [RubyCorrect.root_path('lib', 'ruby_correct', 'ruby_case_gen', 'stubs')]
        env = {'CLASSPATH' => classpath.join(sep)}
        cmd = "jruby bin/ruby_correct case_gen #{args.map {|t| "'#{t}'" }.join(" ")}"
        system(env, cmd)
        exit
      end

      def clear_cache(class_name)
        puts "Clearing cached data..." if options.verbose
        [RubyCorrect.root_path('xml'),
            RubyCorrect.example_path('ruby_case_gen', class_name + '.class'),
            RubyCorrect.example_path('ruby_case_gen', class_name + '.mirah')].each do |file|
          FileUtils.rm_rf(file)
        end
      end

      def convert_to_mirah(ruby_file)
        JRuby.runtime.instance_config.run_ruby_in_process = false # don't munge ruby path
        rubyname = ENV['PATH'].include?('rvm') ? 'rvm 1.9.3 do' : 'ruby'
        system("#{rubyname} bin/ruby_correct mirah #{options.verbose ? '--verbose' : ''} #{ruby_file}")
      end

      def compile_class(class_name)
        Dir.chdir(RubyCorrect.example_path('ruby_case_gen')) do
          jar = RubyCorrect.data_path('ruby_case_gen', 'kiasan.jar')
          %x(mirahc --java -c #{jar} #{class_name}.mirah)
          %x(javac -cp #{jar} *.java)
        end
      end

      def run_kiasan(*args)
        import 'org.sireum.KiasanVM'
        args.unshift *%w(--substitution-extensions SubstitutionProvider)
        args.unshift *%w(--k-bound 10 --invoke-bound 10 --loop-bound 10)
        args.unshift *%w(--print-trace-false-assumption --print-trace-bound-exhausted)
        args.unshift *%w(--quiet) unless options.verbose
        #args.unshift *%w(--generate-pilar)
        KiasanVM.run(args)
      end

      def windows?
        RbConfig::CONFIG['target_os'] =~ /cygwin|mswin|mingw/
      end

      def generate_descriptor(ruby_file, class_name, method_name)
        YARD::Registry.clear
        YARD.parse(ruby_file)
        desc = '()V'
        if obj = YARD::Registry.at("#{class_name}##{method_name}") || obj = YARD::Registry.at("#{class_name}.#{method_name}")
          desc = '('
          desc += obj.tags(:param).map {|t| descriptor_for_type(t.types[0]) }.join
          desc += ')'
          desc += obj.tag(:return) ? descriptor_for_type(obj.tag(:return).types.first) : 'V'
        end
        desc
      end
      
      def descriptor_for_type(type)
        case type
        when /^(.+)\[\]$/; '[' + descriptor_for_type($1)
        when 'Fixnum'; 'I'
        when 'Boolean'; 'Z'
        when 'String'; 'Ljava/lang/String;'
        when 'Integer'; 'Ljava/lang/Integer;'
        when 'Float'; 'D'
        when 'void';   'V'
        else "L#{type};"
        end
      end
    end
  end
end
