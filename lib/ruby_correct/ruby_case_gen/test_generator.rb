require 'digest/sha1'
require 'ruby_correct/ruby_case_gen/kiasan_extensions'

module RubyCorrect
  module RubyCaseGen
    class TestGenerator
      def initialize(class_name, method_name)
        @class_name = class_name
        @method_name = method_name
        @test_num = 0
        @registered_cases = {}
      end

      def generate_cases(test_cases, errors_only = false)
        out = []
        out << "require 'test/unit'"
        out << "require '#{RubyCorrect.example_path('ruby_case_gen', @class_name)}'"
        out << ""
        out << "class Test#{@class_name} < Test::Unit::TestCase"
        test_cases.each do |test_case|
          next unless code = generate_case(test_case, errors_only)
          out << Helpers.indent(code)
          out << ""
        end
        out << "end"
        out << ""
        out.join("\n")
      end

      def generate_case(test_case, errors_only = false)
        return if errors_only && test_case.e0.status == "Normal"
        ruby = test_case.e0.the_call_frame_reports[0].to_ruby
        return unless register_case(ruby)
        fail_case = test_case.e1.the_optional_exception_value
        out = []
        out << "def test_#{@test_num += 1}"
        out.last << " # failure case" if fail_case
        out << Helpers.indent(ruby)
        if retval = test_case.e1.the_optional_return_value
          out << Helpers.indent("assert_equal #{retval.to_ruby}, result")
        elsif out_this = test_case.e1.the_call_frame_reports[0].the_local_value_map['[0]']
          if out_this.respond_to?(:the_optional_field_value_map)
            out_this.the_optional_field_value_map.each do |key, value|
              out << Helpers.indent("assert_equal #{value.to_ruby}, this.#{key}")
            end
          end
        end unless fail_case
        out << "end"
        out.join("\n")
      end

      def register_case(ruby)
        text = ruby.gsub(/\s+/, '')
        key = text.split(//).sort.join
        enc = Digest::SHA1.hexdigest(key)
        if !@registered_cases.has_key?(enc)
          @registered_cases[enc] = true
          true
        else
          false
        end
      end
    end
  end
end
