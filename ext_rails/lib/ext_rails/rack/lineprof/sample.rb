module Rack
  class Lineprof
    class Sample < Struct.new(:ms, :calls, :line, :code, :level)

      def format(colorize = true)
        formatted = if level == CONTEXT
          sprintf "               | % 3i  %s", line, code
        else
          sprintf "% 6.1fms %5i | % 3i  %s", ms, calls, line, code
        end

        return formatted unless colorize

        case level
        when CRITICAL
          formatted.red
        when WARNING
          formatted.yellow
        when NOMINAL
          formatted.white
        else # CONTEXT
          formatted.black
        end
      end
    end
  end
end
