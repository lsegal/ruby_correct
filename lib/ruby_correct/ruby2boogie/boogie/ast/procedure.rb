require_relative 'node'
require_relative 'statement'
require_relative 'expression'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      module AST
        class Procedure < Node
          attr_accessor :program
          attr_accessor :name
          attr_accessor :inline
          attr_reader :params
          attr_reader :out_params
          attr_reader :locals
          attr_accessor :last_expr
          default :labels, []
          default :statements, []
          default :contracts, []

          def initialize(*args)
            reset_variables
            super
            declare_param('self')
            declare_out_param('$result')
            declare_out_param('$exception', 'Exception')
          end

          def hash; name.hash end
          def eql?(other) name == other.name end

          def declare_param(name, type = nil)
            declare(@params, Parameter, name, type)
          end

          def declare_out_param(name, type = nil)
            declare(@out_params, Parameter, name, type)
          end

          def declare_local(name, type = nil)
            declare(@locals, LocalVariableStatement, name, type)
          end

          def add(klass, opts = {})
            statements << expr(klass, opts)
            nil
          end

          def expr(klass, opts = {})
            klass.new({procedure: self}.merge(opts))
          end

          def reset_variables
            @varmap = {}
            @params = []
            @out_params = []
            @locals = []
            @labels = []
          end

          def ref(var_name)
            @varmap[var_name]
          end

          def refs
            @varmap.values
          end

          def regular_refs
            @varmap.values.reject {|v| v == ref_result || v == ref_self || v == ref_exception }
          end

          def ref_result; ref('$result') end
          def ref_exception; ref('$exception') end
          def ref_self; ref('self') end

          def reset_ref(var_name)
            ref = ref(var_name)
            @varmap.delete(var_name)
            declare_local(var_name, ref.type)
          end

          def to_buf(buf)
            to_buf_function(buf)
            buf.append("procedure #{to_s_inline}")
            buf.append(program.method_name(name))
            buf.append("(#{params.join(", ")}) returns (#{out_params.join(", ")})", loc)
            buf.append(";") if statements.nil?
            to_buf_param_typespecs(buf)

            if contracts.size > 0
              buf.append_line("")
              buf.indent(2) do
                contracts.each {|c| c.to_buf(buf) }
              end
            else
              buf.append(" ")
            end

            if statements.nil?
              buf.append_line("") if contracts.size == 0
              return
            end

            unless labels.find {|x| x.name == 'rescueBlock' }
              lbl = LabelStatement.new(procedure: self, name: 'rescueBlock')
              labels.push(lbl)
              statements.push(lbl)
            end

            buf.append_line("{")
            buf.indent do
              locals.each {|l| l.to_buf(buf) }
              to_buf_local_typespecs(buf)
              statements.each {|s| next unless s; s.to_buf(buf) }
            end
            buf.append_line("}", last_expr ? last_expr.loc : nil)
          end

          private

          def declare(list, klass, name, type)
            if ref = ref(name)
              ref.decl.type = type if type
              return ref
            end
            ref = expr(VariableReference, name: name)
            decl = expr(klass, ref: ref, type: program.type(type))
            ref.decl = decl
            list.push(decl)
            @varmap[name] = ref
            ref
          end

          def to_buf_function(buf)
            fname = "$fn.#{program.method_name(name)}"
            buf.append("function #{fname}")
            buf.append("(#{params.join(", ")}) returns (#{out_params.first})", loc)
            buf.append_line(";")
            buf.append("function #{fname}$exception")
            buf.append("(#{params.join(", ")}) returns (#{out_params[1]})", loc)
            buf.append_line(";")
            exprs = []
            contracts.each do |contract|
              next unless contract.name == 'ensures'
              result = contract.expression.to_s
              next if result.include?("$heap") || result.include?("old(")
              result = result.gsub('$result', "#{fname}(#{params.map(&:name).join(", ")})")
              result = result.gsub('$exception', "#{fname}$exception(#{params.map(&:name).join(", ")})")
              exprs << "(#{result})"
            end
            buf.append_line("axiom (forall #{params.join(", ")} :: #{exprs.join(" && ")});")
          end

          def to_buf_param_typespecs(buf)
            return unless program.typecheck
            params.each do |param|
              next unless param.type
              buf.append(" ")
              buf.append("requires $typeof(#{param.name}) <: #{param.type}", param.loc)
            end
          end

          def to_buf_local_typespecs(buf)
            return unless program.typecheck
            locals.values.each do |local|
              buf.append_line("assume $typeof(#{local.name}) == #{local.type};", local.loc)
            end
          end

          def to_s_contracts
            contracts.empty? ? "" : contracts.join(" ") + " "
          end

          def to_s_inline
            inline ? "{:inline 100} " : ""
          end
        end
      end
    end
  end
end
