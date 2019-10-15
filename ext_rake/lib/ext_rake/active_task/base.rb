require_rel '**/*.rb'

module ActiveTask
  class Base
    prepend ActiveTask::Helpers
    prepend ActiveTask::Counts

    EXIT_CODE_HELP = 10

    STEPS_ARGS = IceNine.deep_freeze(%i(
      only
      skip
      step
    ))
    RAILS_ARGS = IceNine.deep_freeze(%i(
      env
      app
      root
    ))
    GEMS_ARGS = IceNine.deep_freeze(%i(
      trace
      silent
      format
      require
    ))

    attr_reader :rake, :task, :options

    def self.protected_args
      STEPS_ARGS + RAILS_ARGS + GEMS_ARGS + [:test]
    end

    def self.steps
      []
    end

    def self.args
      {}
    end

    def self.defaults
      {}
    end

    def initialize(rake, task, args = {}, **defaults)
      @debug = ENV['DEBUG'].to_b
      @rake, @task = rake, task
      @options = self.class.defaults.with_indifferent_access.merge!(defaults).merge!(args.to_h)
    end

    def run
      run_help = _with_environment do |env|
        with_environment(env) do
          before_run
          unless cancel?
            around_run{ _run }
            after_run
          end
        end
      end
    rescue Exception => exception
      before_raise(exception)
      raise
    ensure
      after_ensure(exception) unless run_help
    end

    def cancel?
      @_cancel
    end

    def cancel!
      puts "[#{Time.current.utc}]#{ExtRake::CANCEL}[#{Process.pid}]".red
      @_cancel = true
      after_cancel
    end

    protected

    def with_environment(env); yield end
    def before_run; end
    def around_run; yield end
    def after_run; end
    def after_cancel; end
    def before_raise(exception); end
    def after_ensure(exception); end

    def puts(obj = '', *arg)
      task.puts(obj, *arg)
    end

    def method_missing(name, *args, &block)
      if rake.respond_to? name, true
        rake.__send__(name, *args, &block)
      else
        raise NoMethodError, "No method '#{name}' for #{self.class} or :rake"
      end
    end

    def respond_to_missing?(name, _include_private = false)
      rake.respond_to?(name, true)
    end

    private

    def _run
      _steps.each do |step|
        break if cancel?
        puts "[#{Time.current.utc}]#{ExtRake::STEP}[#{Process.pid}] #{step}".yellow
        send(step)
      end
    end

    def _steps
      steps = self.class.steps

      if @options.only.present?
        steps.select!{ |step| step.to_s.in? @options.only }
      end

      if @options.skip.present?
        steps.reject!{ |step| step.to_s.in? @options.skip }
      end

      if @options.step.present?
        steps = steps.take_while{ |step| step.to_s != @options.step }
        steps << @options.step
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
        time_zone: Time.zone,
      }
      @_environment[:rake_config] = ExtRake.config.instance_variables.each_with_object({}) do |ivar, memo|
        memo[ivar] = ExtRake.config.instance_variable_get(ivar)
      end

      yield(@_environment) unless (run_help = _parse_args)

      run_help
    ensure
      @_environment[:rails_args].each do |arg, value|
        name = "RAILS_#{arg.to_s.upcase}"
        ENV[name] = value
      end
      rails_config = @_environment[:rails_config]
      I18n.locale = rails_config[:locale]
      Time.zone = rails_config[:time_zone]
      @_environment[:rake_config].each do |ivar, value|
        ExtRake.config.instance_variable_set(ivar, value)
      end
      Setting.rollback!
      @_environment.clear
    end

    def _parse_args
      rails_args = @options.extract!(*RAILS_ARGS)
      @options = OpenStruct.new(@options)
      parser = OptionParser.new

      parser.banner = "Usage: rake #{task.name} #{'-- [options]' if self.class.args.any?}"
      self.class.args.each do |arg_name, arg_options|
        if self.class.protected_args.include? arg_name
          raise "protected argurment [#{arg_name}] cannot be used"
        end
        case arg_options.last
        when Symbol, Hash
          validates = arg_options.pop
        end
        parser.on(*arg_options) do |value|
          _validates_arg(validates, arg_name, value)
          @options[arg_name] = value
        end
      end
      STEPS_ARGS.except(:step).each do |arg|
        parser.on("--#{arg}=#{arg.to_s.upcase}", Array){ |list| @options[arg] = list }
      end
      parser.on("--step=STEP"){ |value| @options['step'] = value }
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

      parser.on("-h", "--help", task.full_comment.sub('-- [options]', '')) do
        puts(parser.to_s.split("\n").reject! do |line|
          line.match /--(#{self.class.protected_args.join('|')}|$)/
        end.join("\n"))

        exit EXIT_CODE_HELP
      end if task.full_comment.present?
      # ... for some unknown reason
      parser.on("--"){}

      args = parser.order!(ARGV){}
      parser.parse! args
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

    def _validates_arg(validates, arg_name, value)
      case validates
      when :required, :presence
        raise OptionParser::MissingArgument.new(arg_name) if value.blank?
      when Hash
        validates.each do |validates, validates_args|
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
            raise "Unsupported validates '#{validates}'"
          end
        end
      end
    end
  end
end
