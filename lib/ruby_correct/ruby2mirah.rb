require 'yard'

module RubyCorrect
  module Ruby2Mirah
    class Converter
      KERNEL_CLASS = "KiasanKernel__"

      def initialize
        prefix = "org.sireum.kiasan.profile.jvm.extension"
        @transforms = [[0, "import #{prefix}.Kernel as #{KERNEL_CLASS}\n", false]]
      end

      def convert(src)
        process_methods(src)
        src = insert_types(src.dup)
        src = src.gsub(/\bassert\b/, "#{KERNEL_CLASS}.assertTrue")
        src
      end

      protected

      def process_methods(src)
        ast = YARD.parse_string(src).enumerator
        ast.each do |top|
          top.traverse do |node|
            convert_method(node) if node.type == :def || node.type == :defs
          end
        end
      end

      def convert_method(node)
        docstring = YARD::Docstring.new(node.docstring)
        track_param_tags(node, docstring)
        track_return_tags(node, docstring)
        track_requires_tags(node, docstring)
        track_ensures_tags(node, docstring)
      end

      def track_requires_tags(node, docstring)
        if tag = docstring.tag(:requires)
          stmt = "#{KERNEL_CLASS}.assumeTrue(#{tag.text})\n    "
          @transforms << [node.block.source_range.first, stmt, false]
        end
      end

      def track_ensures_tags(node, docstring)
        if tag = docstring.tag(:ensures)
          stmt = "#{KERNEL_CLASS}.assertTrue(#{tag.text})\n    "
          #@transforms << [node.block.source_range.last - 1, stmt, false]
        end
      end

      def track_param_tags(node, docstring)
        types = docstring.tags(:param).inject({}) do |h,k|
          h[k.name] = k.types.first; h
        end
        node.parameters[0].traverse do |param|
          next unless param.type == :ident
          @transforms << [param.source_range.last, types[param.source], true]
        end if node.parameters[0]
      end

      def track_return_tags(node, docstring)
        if tag = docstring.tag(:return)
          delta = 1
          delta = -1 if node.parameters[0].nil?
          @transforms << [node.parameters.source_range.last + delta, tag.types.first, true]
        end
      end

      def convert_type(type)
        case type
        when 'Fixnum'; 'int'
        when 'Float'; 'double'
        else type
        end
      end

      def insert_types(src)
        @transforms.reverse.each do |loc, type, is_type|
          if is_type
            src.insert(loc+1, ':' + convert_type(type))
          else
            src.insert(loc, type)
          end
        end
        src
      end
    end

    class CLI < CLI::Command
      def description; 'Converts YARD annotated Ruby code to Mirah' end

      def setup_options(opts)
        super
        opts.on('--stdout', 'Prints to stdout') { options.stdout = true }
      end

      def run(*args)
        super(args)
        infile = args.first
        outfile = infile.gsub(/\.rb$/, '.mirah')
        puts "Converting #{infile} to #{outfile}..." if options.verbose
        out = Converter.new.convert(File.read(infile))
        if options.stdout
          puts out
        else
          File.open(outfile, "w") {|f| f.write(out) }
        end
      end
    end
  end
end
