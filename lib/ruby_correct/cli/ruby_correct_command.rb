require 'ruby_correct'
require 'ruby_correct/cli/command'
require 'ruby_correct/ruby_case_gen'
require 'ruby_correct/ruby_esc'
require 'ruby_correct/ruby2mirah'

module RubyCorrect
  module CLI
    class RubyCorrectCommand < Command
      COMMANDS = {
        'esc' => RubyEsc::CLI,
        'case_gen' => RubyCaseGen::CLI,
        'mirah' => Ruby2Mirah::CLI
      }

      def run(*args)
        return print_commands if args.empty?
        COMMANDS[args.first].run(*args[1..-1])
      end

      def print_commands
        puts "Commands:"
        COMMANDS.each do |cmd, klass|
          puts "  #{cmd}\t#{klass.new.description}"
        end
      end
    end
  end
end
