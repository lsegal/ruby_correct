require 'java'

import 'org.sireum.kiasan.profile.jvm.report.FileIO'
import 'org.sireum.kiasan.profile.jvm.util.Util'

module RubyCorrect
  module RubyCaseGen
    class ConcreteValueResolver
      def resolve_reports(glob)
        Dir.glob(glob).map do |file|
          resolve_report(file)
        end.compact
      end

      def resolve_report(file)
        xml = FileIO.read_xml(File.read(file))
        outfile = file.gsub(/-symcase/, '-testcase')
        out = FileIO.symbolic_to_concrete(xml)
        File.open(outfile, "w") {|f| f.write Util.report_xstream.to_xml(out) }
        out
      rescue => e
        STDERR.puts(e.message)
        nil
      end
    end
  end
end
