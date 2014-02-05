require 'set'
require_relative 'node'
require_relative 'statement'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      module AST
        class Program < Node
          default :procedures, Set.new
          default :preamble_procedures, Set.new
          default :functions, ['function $typeof(VALUE) returns (VALUE);', 'function $arrget(VALUE, VALUE) returns (VALUE);']
          default :types, Set.new
          default :axioms, Set.new
          default :constants, Set.new
          default :variables, Set.new
          default :fields, {}
          default :type_set, Set.new
          attr_accessor :lambda_count
          attr_accessor :typecheck

          def initialize(*args)
            @constant_map = {}
            self.lambda_count = 0
            self.typecheck = false
            super
            axiom('(forall x:int :: $typeof(x) == Fixnum)') if typecheck
            axiom '(forall x:int,y:int :: {x%y}{x/y} x%y == x-x / y*y)'
            axiom '(forall x:int,y:int :: {x%y} (0 < y ==> 0 <= x%y && x%y < y) && (y < 0 ==> y < x%y && x%y <= 0))'
            type('Object', 'BasicObject')
            type('Boolean', 'Object')
            type('Fixnum', 'Object')
            declare_constant('$true', type('TrueClass', 'Boolean'))
            declare_constant('$false', type('FalseClass', 'Boolean'))
            declare_constant('$nil', 'NilClass')
            types << TypeStatement.new(name: 'VALUE', alias: 'int')
            types << TypeStatement.new(name: 'field')
            variables << VariableStatement.new(name: '$heap', container_types: ['VALUE', 'field', 'VALUE'])
          end

          def to_buf(buf)
            [types, functions, constants, variables, axioms].each do |list|
              list.each {|l| buf.append_line(l.to_s) }
              buf.append_line("")
            end
            fields.values.each {|f| f.to_buf(buf) }
            buf.append_line("")
            preamble_procedures.each {|p| p.to_buf(buf); buf.append_line("") }
            buf.append_line("")
            buf.append_line("// END PREAMBLE")
            buf.append_line("")
            procedures.each {|p| p.to_buf(buf); buf.append_line("") }
          end

          def axiom(expression)
            axioms << AxiomStatement.new(expression: TokenExpression.new(token: expression))
          end

          def method_name(name)
            {
              '+' => 'add',
              '-' => 'sub',
              '*' => 'mul',
              '/' => 'div',
              '%' => 'mod',
              '^' => 'and',
              '|' => 'or',
              '!' => 'not',
              '==' => 'eq',
              '=' => 'set',
              '<' => 'lt',
              '>' => 'gt',
              '@' => 'at',
              '[]' => 'aref'
            }.each do |sym, rep|
              name = name.gsub(sym, "$#{rep}")
            end
            name
          end

          def declare_constant(name, type = nil)
            ref = VariableReference.new(name: name)
            const = ConstantStatement.new(ref: ref, type: type(type), unique: true)
            ref.decl = const
            constants << const
            @constant_map[name] = ref
          end

          def constant(name)
            @constant_map[name]
          end

          def type(name, superklass = "Object")
            name = name.types.first if YARD::Tags::Tag === name
            name = '$ROOTCLASS' if name && name.empty?
            unless name
              name = "Object"
              superklass = "BasicObject"
            end
            name = name.gsub(':', '$')
            name = name.sub(/<(.+)>$/, '$\1$')
            return name if name[0] =~ /[a-z]/
            return name if type_set.include?(name)
            type_set << name
            superklass = "BasicObject" if name == "Object" && superklass == "Object"
            superklass = nil if name == "BasicObject"
            declare_constant(name, name)
            if superklass
              declare_constant(superklass)
              expr = BinaryExpression.new(lhs: name, op: '<:', rhs: superklass)
              axioms << AxiomStatement.new(expression: expr)
            end
            name
          end
        end
      end
    end
  end
end
