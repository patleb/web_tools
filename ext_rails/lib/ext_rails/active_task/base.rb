# frozen_string_literal: true

module ActiveTask
  class Base
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
    include ActiveSupport::LazyLoadHooks::Autorun

    EXIT_CODE_HELP = 10

    STEPS_ARGS = %i(
      only
      skip
      goto
    )
    RAILS_ARGS = %i(
      env
      app
      root
    )
    GEMS_ARGS = %i(
      trace
      silent
      format
      require
    )

    attr_reader :rake, :task, :options

    def self.protected_args
      STEPS_ARGS + RAILS_ARGS + GEMS_ARGS + [:test]
    end

    def self.steps
      [name.demodulize.underscore]
    end

    def self.args
      {}
    end

    def self.defaults
      {}
    end

    def self.track_count_of(*methods)
      methods.each do |name|
        method_count = track_count_as(name)
        method_count_ivar = "@#{method_count}"

        attr_reader method_count

        with_count = const_defined?(:WithCount) ? const_get(:WithCount) : const_set(:WithCount, Module.new)
        with_count.module_eval do
          define_method name do |*args, **options, &block|
            ivar("#{method_count_ivar}_mutex").synchronize do
              count = ivar(method_count_ivar)
              ivar(method_count_ivar, count += 1)
            end
            super(*args, **options, &block)
          end
        end
      end
    end

    def self.track_count_as(name)
      "#{name.to_s.sub(/[!?]$/, '')}_count"
    end

    def debug?
      @_debug
    end

    def success?
      @_success
    end

    def failure?
      !success?
    end

    def initialize(rake, task, args = {}, **defaults)
      @rake, @task = rake, task
      @options = self.class.defaults.with_indifferent_access.merge!(defaults).merge!(args.to_h)
      @_debug = ENV['DEBUG'].to_b
      @_success = true
      if self.class.const_defined? :WithCount
        with_count = self.class.const_get(:WithCount)
        self.class.prepend with_count
        with_count.instance_methods.each do |name|
          method_count_ivar = "@#{self.class.track_count_as(name)}"
          ivar("#{method_count_ivar}_mutex", Mutex.new)
          ivar(method_count_ivar, 0)
        end
      end
    end

    def run!
      result = run
      raise(result) if failure?
      result
    end

    def run
      result = nil
      run_help = _with_environment do |env|
        with_environment(env) do
          before_run
          unless cancel?
            around_run{ result = _run }
            after_run
          end
        end
      end
      ensure_return = true
    rescue Exception => exception
      result = exception
      @_success = false
      after_rescue(exception)
      ensure_return = true
    ensure
      after_ensure(exception) unless run_help
      return result if ensure_return
    end

    def cancel?
      @_cancel
    end

    def cancel!
      puts_cancel if task.rake_ouput?
      @_cancel = true
      after_cancel
    end

    protected

    def with_environment(env); yield(env) end
    def before_run; end
    def around_run; yield end
    def after_run; end
    def after_cancel; end
    def after_rescue(exception); end
    def after_ensure(exception); end

    def puts_step(name)
      puts "[#{Time.current.utc}]#{Rake::STEP}[#{Process.pid}] #{name}".yellow
    end

    def puts_cancel
      puts "[#{Time.current.utc}]#{Rake::CANCEL}[#{Process.pid}]".magenta
    end

    def read_header(path)
      read_file(path, first: true)
    end

    def read_file(path, first: nil)
      i = 0
      if (path = path.to_s).end_with? '.gz'
        IO.popen("unpigz -c #{path}", 'rb') do |io|
          until io.eof?
            next if (line = io.gets&.scrub('*')).blank?
            yield(line.chomp, i) unless i == 0 && first == false
            i += 1
            break if first
          end
        end
      else
        File.foreach(path, chomp: true) do |line|
          next if (line = line.scrub('*')).blank?
          yield(line, i) unless i == 0 && first == false
          i += 1
          break if first
        end
      end
    end

    # NOTE needed only if using a different Gemfile
    def sh_clean(*cmd, &block)
      Bundler.with_unbundled_env do
        rake.__send__ :sh, *cmd, &block
      end
    end

    def method_missing(name, *args, **options, &block)
      if rake.respond_to? name, true
        rake.__send__(name, *args, **options, &block)
      else
        raise NoMethodError.new("No method '#{name}' for #{self.class} or :rake", name)
      end
    end

    def respond_to_missing?(name, _include_private = false)
      rake.respond_to?(name, true)
    end

    private

    def _run
      result = nil
      _steps.each do |step|
        break if cancel?
        puts_step step if task.rake_ouput?
        result = send(step)
      end
      result
    end

    def _steps
      steps = self.class.steps

      if @options.only.present?
        steps.select!{ |step| step.to_s.in? @options.only }
      end

      if @options.skip.present?
        steps.reject!{ |step| step.to_s.in? @options.skip }
      end

      if @options.goto.present?
        steps = steps.take_while{ |step| step.to_s != @options.goto }
        steps << @options.goto
      end

      steps
    end

    def _with_environment
      @_environment = {}
      @_environment[:rails_args] = RAILS_ARGS.each_with_object({}) do |arg, memo|
        name = "RAILS_#{arg.to_s.upcase}"
        memo[name] = ENV[name]
      end
      @_environment[:rails_config] = {
        locale: I18n.locale,
        timezone: Time.zone,
      }

      yield(@_environment) unless (run_help = _parse_args)

      run_help
    ensure
      @_environment[:rails_args].each do |arg, value|
        name = "RAILS_#{arg.to_s.upcase}"
        ENV[name] = value
      end
      rails_config = @_environment[:rails_config]
      I18n.locale = rails_config[:locale]
      Time.zone = rails_config[:timezone]
      Setting.rollback!
      @_environment.clear
    end

    def _parse_args
      rails_args = @options.extract!(*RAILS_ARGS)
      @options = OpenStruct.new(@options)
      parser = OptionParser.new

      parser.banner = "Usage: rake #{task.name} #{'-- [options]' if self.class.args.any?}"
      validates = []
      self.class.args.each do |arg_name, arg_options|
        if self.class.protected_args.include? arg_name
          raise "protected argurment [#{arg_name}] cannot be used"
        end
        case arg_options.last
        when Symbol, Hash
          validates << [arg_name, arg_options.pop]
        end
        parser.on(*arg_options) do |value|
          @options[arg_name] = value
        end
      end
      STEPS_ARGS.except(:goto).each do |arg|
        parser.on("--#{arg}=#{arg.to_s.upcase}", Array){ |list| @options[arg] = list }
      end
      parser.on("--goto=GOTO"){ |value| @options['goto'] = value }
      RAILS_ARGS.each do |arg|
        parser.on("--#{arg}=RAILS_#{arg.to_s.upcase}"){ |value| rails_args[arg] = value }
      end
      parser.on("--test=TEST"){ |value| @options['test'] = value }
      # rake
      parser.on("--trace"){ Rake.verbose(true) }
      # whenever
      parser.on("--silent"){ Rake.verbose(false) }
      # rspec
      parser.on("--format"){}
      parser.on("--require"){}
      if task.full_comment.present?
        parser.on("-h", "--help", task.full_comment.sub('-- [options]', '')) do
          puts(parser.to_s.lines(chomp: true).reject! do |line|
            line.match /--(#{self.class.protected_args.join('|')}|$)/
          end.join("\n"))
          exit EXIT_CODE_HELP
        end
      end
      # ... for some unknown reason
      parser.on("--"){}

      args = parser.order!(ARGV){}
      parser.parse! args
      validates.each do |arg_name, arg_option|
        Array.wrap(arg_option).each do |option|
          _validates_arg(arg_name, option)
        end
      end
      rails_args.each do |arg, value|
        ENV["RAILS_#{arg.to_s.upcase}"] = value
      end

      false
    rescue SystemExit => exception
      if exception.status != EXIT_CODE_HELP
        raise
      else
        true
      end
    end

    def _validates_arg(arg_name, arg_option)
      value = @options[arg_name]
      case arg_option
      when :required, :presence
        raise OptionParser::MissingArgument.new(arg_name) if value.blank?
      when :exist, :exists
        raise ArgumentError, "--#{arg_name.to_s.dasherize} must exist" unless value.blank? || File.exist?(value)
      when Hash
        arg_option.each do |validates, validates_args|
          case validates
          when :greater_than
            min = Array.wrap(validates_args).first
            raise ArgumentError, "--#{arg_name.to_s.dasherize} must be > #{min}" unless value && value > min
          when :greater_or_equal
            min = Array.wrap(validates_args).first
            raise ArgumentError, "--#{arg_name.to_s.dasherize} must be >= #{min}" unless value && value >= min
          when :less_than
            max = Array.wrap(validates_args).first
            raise ArgumentError, "--#{arg_name.to_s.dasherize} must be < #{max}" unless value && value < max
          when :less_than_or_equal
            max = Array.wrap(validates_args).first
            raise ArgumentError, "--#{arg_name.to_s.dasherize} must be <= #{max}" unless value && value <= max
          when :equal
            exact = Array.wrap(validates_args).first
            raise ArgumentError, "--#{arg_name.to_s.dasherize} must == #{exact}" unless value == exact
          else
            raise "Unsupported validation '#{validates}'"
          end
        end
      end
    end
  end
end
