require 'yard'
require 'ruby_correct'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      class Results
        attr_accessor :errors, :nodemap, :preamble_length

        def initialize(output, nodemap, preamble_length)
          self.errors = {}
          self.nodemap = nodemap
          self.preamble_length = preamble_length
          parse_results(output)
        end

        def valid?; errors.size == 0 end

        def to_s
          return "Success." if valid?
          out = "Verification Errors (#{errors.size}):\n\n"
          errors.each do |point, error|
            out << "- " + error + ":"
            case pt = nodemap[point]
            when YardExtensions::ExpressionTag
              out << "\n      @#{pt.tag_name} #{pt.expression.source}"
            when YARD::Tags::Tag
              out << "\n      @#{pt.tag_name} #{pt.types ? "[#{pt.types.join(", ")}] " : ""}#{pt.name ? pt.name + " " : ""}#{pt.text}"
            when YARD::Parser::Ruby::AstNode
              out << (pt.line - preamble_length).to_s + ":\n      " + pt.source if pt.source
            end
            out << "\n\n"
          end
          out
        end

        private

        def parse_results(output)
          output.split(/\r?\n/).each do |line|
            if line =~ /\((\d+),(\d+)\): (?:Error|Related).*?: (.+?)\.?$/i
              errors[[$1.to_i, $2.to_i]] = $3
            end
          end
        end
      end
    end
  end
end