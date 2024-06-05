require 'rblineprof'
require 'logger'

module Rack
  class Lineprof

    autoload :Sample, 'ext_rails/rack/lineprof/sample'
    autoload :Source, 'ext_rails/rack/lineprof/source'

    CONTEXT  = 0
    NOMINAL  = 1
    WARNING  = 2
    CRITICAL = 3

    DEFAULT_LOGGER = if defined?(::Rails)
      if ::Rails.env.local?
        ::Logger.new(STDOUT)
      else
        ::Logger.new(::Rails.root.join('log/profiler.log'))
      end
    else
      ::Logger.new(STDOUT)
    end

    attr_reader :app, :options

    def initialize(app, **options)
      @app, @options = app, options
    end

    def call(env)
      request = Rack::Request.new(env)
      matcher = request.params['lineprof'] || options[:profile]
      logger  = options[:logger] || DEFAULT_LOGGER

      return @app.call env unless matcher

      response = nil
      profile = lineprof(%r{#{matcher}}) { response = @app.call env }

      logger.error "\n[Rack::Lineprof] #{'=' * 63}".blue + "\n\n" + format_profile(profile) + "\n"

      response
    end

    def format_profile(profile)
      sources = profile.map do |filename, samples|
        Source.new filename, samples, options
      end
      sources.map(&:format).compact.join "\n"
    end
  end
end
