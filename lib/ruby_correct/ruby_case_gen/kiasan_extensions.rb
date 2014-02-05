require 'java'
require 'yard'
require 'ruby_correct/ruby_case_gen'

import 'org.sireum.kiasan.report.ConcreteScalarValueReport'
import 'org.sireum.kiasan.report.NullPrimitiveValueReport'

class Java::OrgSireumKiasanReport::ConcreteScalarValueReport
  def to_ruby; the_value.inspect end
end

class Java::OrgSireumKiasanReport::NullPrimitiveValueReport
  def the_value; nil end
end

class Java::OrgSireumKiasanReport::NullValueReport
  def to_ruby
    'nil'
  end
end

class Java::OrgSireumKiasanReport::ObjectValueReport
  def to_ruby
    util = RubyCorrect::RubyCaseGen::Helpers
    type = util.translate_type(the_type_name)
    out = []
    if type == "String" || type == "Integer"
      out << "#{(the_optional_field_value_map['.value'].to_ruby || "").inspect}"
    else
      out << "#{type}.new.tap do |o|"
      the_optional_field_value_map.each do |k, v|
        out << util.indent("o.#{k.to_s.gsub(/^\./, '')} = #{v.to_ruby}")
      end
      out << "end"
    end
    out.join("\n")
  end
end

class Java::OrgSireumKiasanReport::NonNullValueReport
  def to_ruby
    RubyCorrect::RubyCaseGen::Helpers.value_for_type(the_type_name)
  end
end

class Java::OrgSireumKiasanReport::MaybeNullValueReport
  def to_ruby
    RubyCorrect::RubyCaseGen::Helpers.value_for_type(the_type_name)
  end
end

class Java::OrgSireumKiasanReport::StringValueReport
  def to_ruby
    the_value.to_s
  end
end

class Java::OrgSireumKiasanReport::IntValueReport
  def to_ruby
    the_value
  end
end

class Java::OrgSireumKiasanReport::ConcreteArrayValueReport
  def to_ruby
    out = the_optional_element_values.map do |el|
      el ? el.to_ruby : 'nil'
    end
    "[#{out.join(', ')}]"
  end
end

class Java::OrgSireumKiasanReport::CallFrameReport
  def to_ruby
    name = [the_unit_info.e0, the_unit_info.e1]
    obj = YARD::Registry.at(name.join('#')) || YARD::Registry.at(name.join('.'))
    out, extra = [], obj ? obj.parameters : []
    ([['this', nil]] + extra).map(&:first).each_with_index do |param, i|
      value = the_local_value_map[param]
      base = !obj || obj.scope == :class ? -1 : 0
      if param == 'this' && (!obj || obj.scope == :class)
        value = the_unit_info.e0
      elsif value.nil?
        value = the_local_value_map["[#{i+base}]"]
      end
      next unless value
      value = value.to_ruby.to_s.gsub(/\n/, "\n  ") if value.respond_to?(:to_ruby)
      out << "#{param} = #{value}"
    end
    out << "result = this.#{the_unit_info.e1}(#{extra.map(&:first).join(", ")})"
    out.join("\n")
  end
end
