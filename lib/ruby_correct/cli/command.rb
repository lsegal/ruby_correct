require 'optparse'
require 'ostruct'

module RubyCorrect
  module CLI
    class Command
      attr_reader :options

      def self.run(*args) new.run(*args) end

      def initialize
        @options = OpenStruct.new
      end

      def description; '' end

      def run(*args)
        args = args.first if Array === args.first
        opts = OptionParser.new
        setup_options(opts)
        opts.parse!(args)
        args
      end

      def setup_options(opts)
        opts.on_tail('--verbose', 'Verbose') { options.verbose = true }
      end
    end
  end
end
