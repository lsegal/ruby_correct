require_relative 'node'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      module AST
        class Field < Node
          attr_accessor :name

          def to_buf(buf)
            buf.append_line("const unique #{name}: field;")
          end
        end
      end
    end
  end
end