require_relative 'node'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      module AST
        class Expression < Node; end

        class Parameter < Expression
          attr_accessor :ref
          def name; ref ? ref.to_s : @name end
          def to_s; "#{name}: VALUE" end
        end

        class BinaryExpression < Expression
          attr_accessor :lhs, :op, :rhs
          def to_s; "#{lhs} #{op} #{rhs}" end
        end

        class UnaryExpression < Expression
          attr_accessor :op, :rhs
          def to_s; "#{op}#{rhs}" end
        end

        class TokenExpression < Expression
          attr_accessor :token
          alias to_s token
        end

        class FunctionExpression < Expression
          attr_accessor :name
          default :parameters, []
          def to_s; "#{name}(#{parameters.join(", ")})" end
        end

        class ParenthesisExpression < Expression
          attr_accessor :expression
          def to_s; "(#{expression})" end
          def type; expression.type end
        end

        class FieldReference < Expression
          attr_accessor :field
          alias decl field
          def type; decl.type end
          def to_s; "$heap[self][#{field.name}]" end
        end

        class VariableReference < Expression
          undef type, type=
          attr_accessor :name
          attr_accessor :decl
          def type; decl.type end
          def to_s; name end
        end
      end
    end
  end
end