require 'ruby_correct'
require 'ruby_correct/ruby2boogie/boogie/translator'
require 'ruby_correct/cli/command'

module RubyCorrect
  module Ruby2Boogie
    class Converter
      def self.preamble
        @preamble ||= File.read(RubyCorrect.data_path('ruby2boogie', 'preamble.rb'))
      end

      def convert(str)
        YARD::Registry.clear
        YARD.parse_string([self.class.preamble, str].join("\n\n"))
        program = Boogie::AST::Program.new
        YARD::Registry.all(:class).each do |klass|
          Boogie::ClassTranslator.new(program).parse_class(klass)
        end
        YARD::Registry.all(:method).reject {|m| m.has_tag?(:core) }.each do |method|
          Boogie::MethodTranslator.new(program).parse_method(method)
        end
        program
      end
    end
  end
end