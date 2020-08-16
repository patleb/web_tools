require 'ext_rails/rack/lineprof'

class Lineprof
  IGNORE_PATTERN  = /lib\/lineprof\.rb$/
  DEFAULT_PATTERN = /./

  class << self
    def profile(filename = caller_filename(caller), **options, &block)
      value  = nil
      result = lineprof(filename) { value = block.call }

      puts Term::ANSIColor.blue("\n[Lineprof] #{'=' * 70}")
      puts "\n#{format(result, **options)}\n"
      value
    end

    private

    def caller_filename(caller_lines)
      caller_lines.first.split(':').first || DEFAULT_PATTERN
    end

    def format(result, **options)
      sources = result.map do |filename, samples|
        next if filename =~ IGNORE_PATTERN
        Rack::Lineprof::Source.new(filename, samples, **options)
      end
      sources.compact.map(&:format).compact.join("\n")
    end
  end
end
