require 'rubygems'
require 'yard'

module RubyCorrect
  module YardExtensions
    class ExpressionTag < YARD::Tags::Tag
      include YARD::Parser::Ruby

      attr_accessor :expression
      def initialize(tag, expr)
        super(tag, nil)
        self.expression = expr
      end
    end

    class MethodHandler < YARD::Handlers::Ruby::MethodHandler
      handles :def

      def register(obj) super; @obj = obj end

      def process
        super
        @obj.docstring.add_tag(ExpressionTag.new(:ast, statement.block))
        @obj.docstring.delete_tags(:return) if statement.docstring !~ /@return/
      end
    end
  end
end

class YARD::Tags::Library
  define_tag 'Precondition', :requires
  define_tag 'Postcondition', :ensures
  define_tag 'Modifies Clause', :modifies
  define_tag 'Invariant', :invariant
  define_tag 'Pure Function', :pure
  define_tag 'AST', :ast, RubyCorrect::YardExtensions::ExpressionTag
  define_tag 'Instance Variable', :ivar, :with_types_and_name
  define_tag 'Local Variable', :local, :with_types_and_name
  define_tag 'Boogie Implementation', :boogie_impl
  define_tag 'Core Class', :core

  self.transitive_tags << :core
end
