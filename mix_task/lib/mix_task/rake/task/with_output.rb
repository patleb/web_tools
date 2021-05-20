module Rake::Task::WithOutput
  extend ActiveSupport::Concern

  prepended do
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::NumberHelper

    attr_accessor :output
  end

  def puts(obj = '', *arg, output: rake_ouput?)
    if output
      self.output ||= ''
      self.output << ERB::Util.html_escape(obj) << "\n"
    end
    super(obj, *arg)
  end

  def puts_started(args)
    Log.task(name, args: args.to_h.merge(argv: ARGV.drop(1).except('--')).reject{ |_, v| v.blank? })
    puts "[#{Time.current.utc}]#{MixTask::STARTED}[#{Process.pid}] #{name}".blue
  end

  def puts_success(total)
    Log.task(name, time: total)
    puts "[#{Time.current.utc}]#{MixTask::SUCCESS}[#{Process.pid}] #{name}: #{distance_of_time total}".green
  end

  def puts_failure(exception)
    Notice.deliver! Rescues::RakeError.new(exception, data: { task: name }), subject: name
    puts "[#{Time.current.utc}]#{MixTask::FAILURE}[#{Process.pid}] #{name}".red
  end

  def puts_downloading(file_name, remainder, total)
    remainder = number_to_human_size remainder
    total = number_to_human_size total
    puts "Downloading #{file_name}[#{Process.pid}][#{total}] remaining #{remainder}"
  end

  def execute(args = nil)
    unless rake_ouput?
      if ENV['RAKE_PROFILE']
        require 'ext_rails/lineprof'
        result = nil
        Lineprof.profile(%r{#{ENV['RAKE_PROFILE']}}) do
          result = super
        end
        return result
      elsif name == 'environment' || name.start_with?('db:')
        return super
      else
        return with_db_loggers{ super }
      end
    end

    started_at = Concurrent.monotonic_time
    self.output = ''
    I18n.with_locale(:en) do
      Time.use_zone('UTC') do
        with_db_loggers do
          puts_started args
          super
        rescue Exception => exception
          raise
        ensure
          if exception
            puts_failure exception
          else
            total = (Concurrent.monotonic_time - started_at).seconds.ceil(3)
            puts_success total
          end
        end
      end
    end

    output.dup
  end

  def rake_ouput?
    ARGV.exclude?('--help') && name != 'environment' && ENV['RAKE_OUTPUT'].to_b
  end

  def with_db_loggers
    if Rails.env.development?
      @_ar_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = ::Logger.new(STDOUT)
    end
    yield
  ensure
    if Rails.env.development?
      ActiveRecord::Base.logger = @_ar_logger
    end
  end
end
