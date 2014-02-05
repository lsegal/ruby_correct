require 'set'
require_relative 'ast/procedure'
require_relative 'ast/program'
require_relative 'ast/statement'
require_relative 'ast/expression'
require_relative 'ast/field'

module RubyCorrect
  module Ruby2Boogie
    module Boogie
      class TranslationError < RuntimeError; end

      module TranslatorMethods
        include AST
        include YARD::Parser::Ruby

        def parse_ast(ast)
          return unless ast
          visit(ast)
          if procedure.statements.map {|c| c.class }.include?(CallStatement)
            procedure.declare_local('$unused')
          end
        end

        def visit_block(block = nil, &exec_block)
          stmts, procedure.statements = procedure.statements, []
          visit(block) if block
          yield if block_given?
          result, procedure.statements = procedure.statements, stmts
          result
        end

        def translate_rescue(block)
         add(LabelStatement, name: 'rescueBlock', loc: block)
         add(AssignmentStatement, lhs: ref('$exception'), rhs: program.constant('$nil'), loc: block)
         visit(block[2])
        end
        
        def translate_binary(bin)
          case bin[1].to_s
          when '&&', '||'
            expr(BinaryExpression, lhs: visit(bin[0]), op: bin[1], rhs: visit(bin[2]), loc: bin)
          else
            args = [s(:var_ref, bin[0]), :".", s(:ident, bin[1].to_s), s(s(bin[2]), false)]
            if ref = add_call(MethodCallNode.new(:call, args), bin)
              ref
            else # fallback
              expr(BinaryExpression, lhs: visit(bin[0]), op: bin[1], rhs: visit(bin[2]), loc: bin)
            end
          end
        end

        def translate_unary(unary)
          name = unary[0].to_s
          name = '-@' if name == '-'
          args = [unary[1], :".", s(:ident, name), s(s(), false)]
          if ref = add_call(MethodCallNode.new(:call, args), unary)
            ref
          else # fallback
            expr(UnaryExpression, op: unary[0], rhs: visit(unary[1]), loc: unary)
          end
        end

        def translate_paren(paren)
          expr(ParenthesisExpression, expression: visit(paren.first.first), loc: paren)
        end

        def translate_return(ret)
          add(ReturnStatement, expression: visit(ret.first.first), loc: ret)
        end

        def translate_var_ref(ref) visit(ref[0]) end

        def translate_int(int) token(int.source, 'Fixnum') end

        def translate_var_field(field)
          # about to be assigned
          node = field.first
          name = node.source
          procedure.declare_local(name) if node.type == :ident
          if param = procedure.params.find {|p| p.name == name } # it's a parameter
            # rewrite parameter as param$in and assign it to local
            oldref = ref(name)
            oldref.name += '$in'
            newref = procedure.reset_ref(name)
            add(AssignmentStatement, lhs: newref, rhs: oldref, loc: field.parent)
          end
          visit(node)
        end

        def translate_kw(kw)
          case kw.source
          when 'true', 'false', 'nil'
            program.constant("$#{kw.source}")
          when 'self'
            ref('self')
          else
            token(kw.source)
          end
        end

        def translate_ifop(stmt)
          var = procedure.declare_local("retval$#{self.assignment_count += 1}")
          var.loc = stmt
          then_block = visit_block do
            add(AssignmentStatement, lhs: var, rhs: visit(stmt[1]), loc: stmt[1])
          end
          else_block = visit_block do
            add(AssignmentStatement, lhs: var, rhs: visit(stmt[2]), loc: stmt[2])
          end
          var.decl.type = then_block.last.rhs.decl.type
          add IfStatement, loc: stmt[0],
            condition: to_condition(visit(stmt[0])),
            then: then_block,
            else: else_block
          self.last_expr = var
        end
        
        def translate_if(stmt)
          add IfStatement, loc: stmt.condition,
            condition: to_condition(visit(stmt.condition)),
            then: visit_block(stmt.then_block),
            else: visit_block(stmt.else_block)
        end
        alias translate_if_mod translate_if

        def translate_unless(stmt)
          add IfStatement, loc: stmt.condition,
            condition: to_condition(visit(stmt.condition), '$false'),
            then: visit_block(stmt.then_block),
            else: visit_block(stmt.else_block)
        end
        alias translate_unless_mod translate_unless
        
        def translate_while(stmt)
          docstring = YARD::Docstring.new(stmt.docstring)
          invariants = docstring.tags(:invariant).map do |tag|
            InvariantTranslator.new(program, procedure).parse_invariant(tag)
          end
          stmts, procedure.statements = procedure.statements, []
          cond = to_condition(visit(stmt[0]))
          cond_stmts, procedure.statements = procedure.statements, stmts
          procedure.statements += cond_stmts
          block = visit_block(stmt[1]) + cond_stmts
          add(WhileStatement, loc: stmt[0], condition: cond, block: block, invariants: invariants)
        end

        def translate_assign(assign)
          if assign[0].type == :aref_field
            aref = assign[0]
            args = [aref[0], :".", s(:ident, "[]="), s(s(aref[1][0], assign[1]), false)]
            call = MethodCallNode.new(:call, args)
            call.source_range = assign.source_range
            return add_call(call, aref)
          end
          lhs = visit(assign[0])
          rhs = visit(assign[1])
          if rhs.type && lhs.type == 'Object'
            lhs.decl.type = rhs.type # simple inference
          end
          add(AssignmentStatement, lhs: lhs, rhs: rhs, loc: assign)
          self.last_expr = lhs
        end

        def translate_opassign(assign)
          op = assign[1].source[0]
          node = s(:assign, assign[0], s(:binary, assign[0], op, assign[2]))
          node.source_range = assign.source_range
          node.line_range = assign.line_range
          translate_assign(node)
        end

        def translate_ivar(ivar)
          name = procedure_class + "$" + ivar[0][1..-1]
          program.fields[name] ||= expr(Field, name: name)
          self.last_expr = expr(FieldReference, field: program.fields[name])
        end

        def translate_string_literal(str)
          name = "STRING$#{self.literal_count += 1}"
          self.last_expr = procedure.declare_local(name, 'String')
        end

        def translate_ident(ident)
          self.last_expr = ref(ident[0])
        end

        def translate_array(array)
          name = "ARRAY$#{self.literal_count += 1}"
          ref = procedure.declare_local(name, 'Array')
          args = [s(:var_ref, s(:ident, ref.name)), :".", s(:ident, "initialize"), s(s(), false)]
          add_call(MethodCallNode.new(:call, args), array)
          if array.last
            array.last.each do |arg|
              args = [s(:var_ref, s(:ident, ref.name)), :".", s(:ident, "push"), s(s(arg), false)]
              add_call(MethodCallNode.new(:call, args), arg)
            end
          end
          self.last_expr = ref
        end

        def translate_aref(aref)
          args = [aref[0], :".", s(:ident, "[]"), aref[1]]
          add_call(MethodCallNode.new(:call, args), aref)
        end
        alias translate_aref_field translate_aref

        def translate_const(const)
          obj = YARD::Registry.at(const.source)
          if obj.is_a?(YARD::CodeObjects::NamespaceObject)
            self.last_expr = program.constant(const.source)
          else
            self.last_expr = token(const.source)
          end
        end

        def translate_call(call)
          add_call(call)
        end
        alias translate_command_call translate_call

        def translate_fcall(call)
          name = call.first.source
          return translate_assert(call, name) if %w(assert assume).include?(name)
          add_call(call)
        end
        alias translate_command translate_fcall
        alias translate_vcall translate_fcall

        def translate_assert(call, type = 'assert')
          klass = type == 'assert' ? AssertStatement : AssumeStatement
          expr = visit(call.last[0])
          expr = expr.first if expr.is_a?(Array)
          add(klass, expression: to_condition(expr), loc: call)
        end

        def translate_arg_paren(paren)
          translate_list(paren)
        end

        def translate_list(list)
          list.map {|n| visit(n) if n.is_a?(AstNode) }.compact
        end

        protected

        def procedure_class
          procedure_method.namespace.path
        end

        def procedure_method
          procedure.loc
        end

        def lookup_method(name, klass = nil)
          klass ||= procedure_method.namespace
          klass = YARD::Registry.at(klass) if klass.is_a?(String)
          YARD::Registry.resolve(klass, name.to_s, true)
        end

        def add(klass, opts = {})
          procedure.add(klass, opts)
        end

        def add_call(call, loc = call)
          name = call.method_name(true).to_s
          obj = call.namespace ? visit(call.namespace) : ref('self')
          is_class_scope = call.namespace && call.namespace[0].is_a?(AstNode) ? (call.namespace[0].type == :const) : class_scope
          name = "##{name}" unless is_class_scope
          typeklass, ret_type = obj.type, nil
          if typeklass =~ /^(.+?)\$(.+?)\$$/
            typeklass, ret_type = $1, $2
          end
          typeklass = 'Object' if typeklass == '$T'
          args = [obj] + [visit(call.parameters)].flatten
          extra_refs = []
          if method = lookup_method(name, typeklass)
            path = method.path
            if tag = method.tag(:return)
              ret_type = tag.types.first if tag.types && tag.types.first != 'Object'
              ret_type = obj.type if ret_type == 'self'
              ret_type = obj.type.split('$')[1] if tag.types && ret_type == '$T'
            end
            if call.block
              args += procedure.refs.reject {|r| r.name =~ /\$/ }
              args = args.compact
              translator = LambdaTranslator.new(program)
              translator.lambda = call.block
              translator.translator = self
              translator.parse_method(method)
              path = translator.procedure.name
              extra_refs = procedure.regular_refs.reject {|r| r.name =~ /\$/ }
            end
            ref = add_call_statement({name: path, parameters: args, loc: loc}, method.tag(:return), extra_refs)
            ref.decl.type = program.type(ret_type, typeklass) if ret_type && ref.respond_to?(:decl)
            ref
          elsif name == '#raise'
            excklass = call.parameters.size > 0 ? call.parameters[0].source : 'RuntimeException'
            superklass = excklass == 'Exception' ? 'Object' : 'Exception'
            ref = add_call_statement({name: 'Object.new', parameters: [program.constant(excklass)], loc: loc}, program.type(excklass, superklass))
            add(AssignmentStatement, lhs: ref('$exception'), rhs: ref, loc: call)
            add(ReturnStatement, loc: call)
            ref('$exception')
          else
            raise TranslationError, "cannot resolve method `#{name}' on #{typeklass}:\n#{loc.source ? loc.show : ""}"
          end
        end

        def add_call_statement(opts = {}, type = nil, extra_outs = [])
          opts[:parameters] ||= []
          opts[:parameters].compact!
          name = "retval$#{self.assignment_count += 1}"
          canraise = false
          if obj = YARD::Registry.at(opts[:name])
            if obj == procedure_method
              tr = self
            else
              tr = MethodTranslator.new(program)
              tr.parse_method(obj, opts[:parameters].map {|t| t.type })
            end
            opts[:name] = tr.procedure.name
            type = get_call_type(obj, type, opts)
            canraise = true if obj.tag(:raise)
          end
          var = procedure.declare_local(name, type)
          exc = procedure.ref('$exception')
          add(CallAssignmentStatement, lhs: [var, exc] + extra_outs,
            rhs: expr(CallStatement, opts), loc: opts[:loc])
          if canraise
            add IfStatement,
              condition: expr(BinaryExpression, lhs: exc, op: '!=', rhs: program.constant('$nil'), loc: opts[:loc]),
              then: [expr(GotoStatement, label: 'rescueBlock', loc: opts[:loc])],
              loc: opts[:loc]
          end
          self.last_expr = var
        end

        def add_contracts(docstring, translator_class = ContractTranslator)
          %w(requires ensures).each do |tname|
            docstring.tags(tname).each do |tag|
              parser = translator_class.new(program, procedure)
              procedure.contracts << parser.parse_contract(tag)
            end
          end

          # modifies tags work a little differently
          ivars = docstring.tags('modifies').map do |tag|
            cls, name = tag.text.split('@')
            cls = procedure_class if cls.empty?
            "f == #{cls}$#{name}"
          end
          if ivars.size > 0
            expr = "(forall o:VALUE, f:field :: $heap[o][f] == old($heap[o][f]) || (o == self && (#{ivars.join(' || ')})))"
            procedure.contracts << expr(ContractStatement, name: 'ensures', expression: expr, loc: docstring.tag('modifies'))
          end
        end

        def get_call_type(obj, type, opts)
          type = program.type(obj.tag(:return)) if type.nil?
          type = type.types.first if type.respond_to?(:types)
          if type == '$T'
            type = opts[:parameters].first.type.split('$')[1]
          end
          type
        end
        
        def to_condition(cond, rhs = '$true')
          if cond.is_a?(BinaryExpression)
            cond
          else
            expr(BinaryExpression, lhs: cond, op: '==', rhs: program.constant(rhs))
          end
        end

        def expr(klass, opts = {})
          procedure.expr(klass, opts)
        end

        def token(token, type = nil)
          expr(TokenExpression, token: token, type: program.type(type))
        end

        def ref(var_name)
          procedure.ref(var_name)
        end
      end

      class Translator
        include AST
        include YARD::Parser::Ruby

        attr_accessor :program

        def initialize(program = nil)
          self.program = program || Program.new
        end

        def visit(node)
          return [] unless node.is_a?(AstNode)
          m = "translate_#{node.type}"
          send(m, node) if respond_to?(m)
        end
      end

      class ClassTranslator < Translator
        def parse_class(klass)
          program.type(klass.path, klass.superclass.path)
          klass.tags(:ivar).each do |tag|
            name = klass.path + "$" + tag.name
            program.fields[name] ||= Field.new(name: name, type: program.type(tag), loc: tag)
          end
        end
      end

      class MethodTranslator < Translator
        include TranslatorMethods

        attr_accessor :procedure
        attr_accessor :literal_count
        attr_accessor :assignment_count
        attr_accessor :class_scope
        attr_accessor :last_expr

        def initialize(program = nil, procedure = nil)
          super(program)
          self.procedure = procedure || Procedure.new(program: program)
          self.literal_count = 0
          self.assignment_count = 0
          self.class_scope = false
          self.last_expr = nil
        end

        def parse_method(method, types = nil)
          self.class_scope = true if method.scope == :class
          procedure.loc = method
          procedure.ref_self.decl.type = types ? types[0] : program.type(procedure_class)
          procedure.ref_result.decl.type = program.type(method.tag(:return))
          method.parameters.each.with_index do |(name, v), idx|
            if types
              param = types[idx+1]
            else
              param = method.tags(:param).find {|x| x.name == name }
            end
            procedure.declare_param(name, param).decl
          end
          procedure.name = procedure_name(method, types)
          add_contracts(method.docstring)

          unless method.has_tag?(:pure)
            procedure.contracts << expr(ContractStatement, name: 'modifies', expression: '$heap')
          end

          method.tags(:local).each do |local|
            procedure.declare_local(local.name, local)
          end

          expr = method.tag(:ast)
          if tag = method.tag(:boogie_impl)
            procedure.statements = [token(tag.text.strip)]
          else
            if tag = method.tag(:ast)
              expr = tag.expression
            else
              expr = RubyParser.new(method.source, '<stdin>').parse.enumerator[0].block
            end
            if expr == s(s(:void_stmt))
              procedure.statements = nil
            else
              procedure.statements <<
                AssignmentStatement.new(procedure: procedure, loc: method, lhs: ref('$exception'), rhs: program.constant('$nil'))
              parse_ast(expr)
              if last_expr
                procedure.statements <<
                  AssignmentStatement.new(procedure: procedure, loc: last_expr.loc, lhs: ref('$result'), rhs: last_expr)
                procedure.last_expr = last_expr
              end
            end
          end

          if method.tag(:core)
            program.preamble_procedures << procedure
          else
            program.procedures << procedure
          end
        end

        def procedure_name(method, types = nil)
          types ||= procedure.params.map {|decl| decl.type }
          method.path + (types ? "$#{types.join("$")}" : "")
        end
      end

      class LambdaTranslator < MethodTranslator
        attr_accessor :lambda
        attr_accessor :translator
        attr_accessor :in_lambda

        def parse_ast(ast)
          self.in_lambda = false
          procedure.inline = true
          procedure.name += "$lambda$#{translator.procedure.name}$#{program.lambda_count += 1}"
          translator.procedure.refs.each do |ref|
            case ref.name
            when /\$/
              nil
            when 'self'
              procedure.declare_param("#{ref.name}$lambda$in", ref.type)
            else
              in_ = procedure.declare_param("#{ref.name}$lambda$in", ref.type)
              out_ = procedure.declare_out_param("#{ref.name}$lambda$out", ref.type)
              add(AssignmentStatement, lhs: out_, rhs: in_)
            end
          end
          super(ast)
        end

        def translate_paren(paren)
          translate_list(paren[0])
        end

        def translate_yield(node)
          self.in_lambda = true
          docstring = YARD::Docstring.new(lambda.parent.docstring)
          params = translate_params(docstring)
          node[0][0].each.with_index do |param, i|
            next unless param.is_a?(AstNode)
            add(AssignmentStatement, lhs: params[i], rhs: visit(param), loc: node)
          end
          (docstring.tags('requires') + docstring.tags('invariant')).each do |tag|
            parser = LambdaContractTranslator.new(program, procedure)
            add(AssertStatement, expression: parser.parse_contract(tag).expression, loc: tag)
          end
          visit(lambda.last)
          (docstring.tags('ensures') + docstring.tags('invariant')).each do |tag|
            parser = LambdaContractTranslator.new(program, procedure)
            add(AssertStatement, expression: parser.parse_contract(tag).expression, loc: tag)
          end
          self.in_lambda = false
        end
        alias translate_yield0 translate_yield

        def translate_params(docstring)
          lambda[0][0].first.map do |ident|
            name = ident.source
            param = docstring.tags(:local).find {|x| x.name == name }
            procedure.declare_local("#{name}$lambda$out", param)
          end
        end

        def translate_var_field(field)
          if in_lambda && ref = ref(field.source)
            ref
          else
            super(field)
          end
        end

        def translate_ident(ident)
          if in_lambda && ref = ref(ident.source)
            ref
          else
            procedure.ref(ident.source)
          end
        end

        def ref(name)
          if in_lambda
            if name == 'self'
              ref = super(name)
            else
              ref = super(name + "$lambda$out")
            end
          else
            ref = super(name)
          end
          ref
        end
      end

      module ContractExpressionParser
        include AST
        include YARD::Parser::Ruby

        attr_accessor :tag

        def parse_contract(tag)
          self.tag = tag
          expr = parse_expression(tag.text)
          expr = to_condition(expr) if expr.is_a?(FunctionExpression)
          expr(ContractStatement, name: tag.tag_name, expression: expr, loc: tag)
        end

        def parse_expression(expression)
          ast = RubyParser.new(expression, '<stdin>').parse.enumerator[0]
          visit(adjust_ast(ast))
        end

        def adjust_ast(ast)
          ast.traverse do |node|
            if node == s(:var_ref, s(:gvar, "$result"))
              node[0].type = :result
            elsif node == s(:var_ref, s(:gvar, "$exception"))
              node[0].type = :exception
            elsif node.type == :vcall && ref(node[0].source)
              node.type = :var_ref
            elsif node.type == :fcall && node[0] == s(:ident, "old")
              node.type = :old
              node.replace(node.parameters[0])
            end
          end
          ast
        end

        def translate_result(res)
          ref('$result')
        end

        def translate_exception(exc)
          ref('$exception')
        end

        # Uncomment to disable operator mangling in contracts
        def translate_binary(bin)
          expr(BinaryExpression, lhs: visit(bin[0]), op: bin[1], rhs: visit(bin[2]), loc: bin)
        end

        def translate_old(old)
          arg = visit(old[0])
          ex = expr(FunctionExpression, name: 'old', parameters: [arg])
          ex.type = arg.type
          ex
        end

        def translate_string_literal(str)
          token(str.source[1...-1])
        end

        def translate_if_mod(stmt)
          expr(BinaryExpression, lhs: to_condition(visit(stmt.condition)), op: '==>', rhs: to_condition(visit(stmt.then_block)), loc: stmt)
        end

        def add_call_statement(opts = {}, type = nil, extra_outs = [])
          if obj = YARD::Registry.at(opts[:name])
            if obj == procedure_method
              tr = self
            else
              tr = MethodTranslator.new(program)
              tr.parse_method(obj, opts[:parameters].map {|t| t.type })
            end
            opts[:name] = "$fn.#{program.method_name(tr.procedure.name)}"
            ex = expr(FunctionExpression, opts)
            ex.type = get_call_type(obj, type, opts)
            ex
          end
        end
      end

      class ContractTranslator < MethodTranslator
        include ContractExpressionParser
      end

      class LambdaContractTranslator < LambdaTranslator
        include ContractExpressionParser

        def in_lambda; true end

        def translate_binary(bin)
          expr(BinaryExpression, lhs: visit(bin[0]), op: bin[1], rhs: visit(bin[2]), loc: bin)
        end

        def translate_string_literal(str)
          token(str.source[1...-1])
        end

        def translate_if_mod(stmt)
          expr(BinaryExpression, lhs: visit(stmt.condition), op: '==>', rhs: visit(stmt.then_block), loc: stmt)
        end

        def translate_old(old)
          if ref = procedure.ref("#{old[0].source}$lambda$in")
            ref
          else
            super(old)
          end
        end
      end

      class InvariantTranslator < ContractTranslator
        def parse_invariant(tag)
          expr = parse_expression(tag.text)
          expr = to_condition(expr) if expr.is_a?(FunctionExpression)
          expr(ContractStatement, name: tag.tag_name, expression: expr, loc: tag)
        end
      end
    end
  end
end
