require_relative 'node'
require_relative 'procedure'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      module AST
        class Statement < Node
          attr_accessor :procedure
          def to_buf(o) o.append_line(to_s, loc) end
        end

        class AxiomStatement < Statement
          attr_accessor :expression
          def to_s; "axiom #{expression};" end
        end

        class TypeStatement < Statement
          attr_accessor :name, :alias
          def to_s; "type #{name}#{to_s_alias};" end
          def eql?(other) name == other.name end
          def hash; name.hash end
          private
          def to_s_alias; self.alias ? " = #{self.alias}" : "" end
        end

        class VariableStatement < Statement
          attr_accessor :name
          default :container_types, ['VALUE']
          def to_s; "var #{name}: #{to_s_container_types};" end
          def eql?(other) name == other.name end
          def hash; name.hash end
          private
          def to_s_container_types
            container_types.map.with_index do |type, i|
              container_types.size == i + 1 ? type : "[#{type}]"
            end.join
          end
        end

        class ConstantStatement < VariableStatement
          default :container_types, ['VALUE']
          attr_accessor :ref
          def name; ref ? ref.name : @name end
          attr_accessor :unique
          def to_s; "const #{unique ? 'unique ' : ''}#{name}: #{to_s_container_types};" end
        end

        class ContractStatement < Statement
          attr_accessor :name, :expression
          def to_s; "#{name} #{expression};" end
        end

        class AssignmentStatement < Statement
          attr_accessor :lhs, :rhs

          def to_buf(o)
            if lhs.is_a?(Array)
              lhs.each.with_index do |l, i|
                l.to_buf(o)
                o.append(", ") if lhs.size != i + 1
              end
            else
              lhs.to_buf(o)
            end
            o.append(" := ", loc)
            rhs.to_buf(o)
            o.append_line(";")
          end
        end

        class LocalVariableStatement < VariableStatement
          undef name, name=
          attr_accessor :ref
          default :container_types, ['VALUE']
          def name; ref.to_s end
        end

        class AssertStatement < Statement
          attr_accessor :expression
          def to_s; "assert #{expression};" end
        end

        class AssumeStatement < Statement
          attr_accessor :expression
          def to_s; "assume #{expression};" end
        end

        class CallStatement < Statement
          attr_accessor :name
          default :parameters, []

          def to_buf(o)
            o.append("call $unused", loc)
            o.append(" := ", loc)
            o.append(procedure.program.method_name(name), loc)
            o.append_line("(" + parameters.join(', ') + ");")
          end
        end

        class CallAssignmentStatement < AssignmentStatement
          def to_buf(o)
            o.append("call ", loc)
            if lhs.is_a?(Array)
              lhs.each.with_index do |l, i|
                l.to_buf(o)
                o.append(", ") if lhs.size != i + 1
              end
            else
              lhs.to_buf(o)
            end
            o.append(" := ", loc)
            o.append(procedure.program.method_name(rhs.name), loc)
            o.append_line("(#{rhs.parameters.join(', ')});");
          end
        end

        class ReturnStatement < Statement
          attr_accessor :expression
          def to_buf(o)
            o.append_line("$result := #{expression};") if expression
            o.append_line("return;", loc)
          end
        end

        class IfStatement < Statement
          attr_accessor :condition
          default :then, []
          default :else, []

          def to_buf(o)
            o.append("if (");
            condition.to_buf(o)
            o.append_line(") {")
            o.indent { self.then.each {|t| t.to_buf(o) } }
            o.append_line("}")
            if self.else.size > 0
              o.append_line("else {")
              o.indent { self.else.each {|e| e.to_buf(o) } }
              o.append_line("}")
            end
          end
        end

        class WhileStatement < Statement
          attr_accessor :condition
          default :invariants, []
          default :block, []

          def to_buf(o)
            o.append("while (");
            condition.to_buf(o)
            o.append(")")
            invariants.each do |invariant|
              o.append(" "); invariant.to_buf(o)
            end
            o.append_line(" {")
            o.indent { block.each {|t| t.to_buf(o) } }
            o.append_line("}")
          end
        end

        class GotoStatement < Statement
          attr_accessor :label
          def to_s; "goto #{label};" end
        end
        
        class LabelStatement < Statement
          attr_accessor :name

          def initialize(*args)
            super
            if procedure
              if name != 'rescueBlock'
                self.name += procedure.labels.select {|l| l.name.start_with?(name) }.size.to_s
              end
              procedure.labels |= [self]
            end
          end

          def to_s; "#{name}:" end
          def to_buf(o)
            o.indent(-o.indent) { o.append_line(to_s, loc) }
          end
        end
      end
    end
  end
end
