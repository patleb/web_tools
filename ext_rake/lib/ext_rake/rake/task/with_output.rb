module Rake::Task::WithOutput
  extend ActiveSupport::Concern

  prepended do
    attr_accessor :output
  end

  def puts(obj = '', *arg)
    self.output ||= ''
    self.output << ERB::Util.html_escape(obj) << "\n"
    super
  end

  def execute(args = nil)
    return super if skip_ouput?

    start = Time.current.utc
    self.output = ''
    I18n.with_locale(:en) do
      Time.use_zone('UTC') do
        with_db_loggers do
          puts "#{ExtRake::STARTED} #{name}".blue
          super
        rescue Exception => exception
          # TODO use MrRescue
          Notice.new.deliver! exception, subject: name do |message|
            puts message
          end
        ensure
          puts "[#{start}]#{ExtRake::TASK}" if output.exclude? ExtRake::STEP
          finish = Time.current.utc
          puts "[#{finish}]#{ExtRake::DONE}"
          total = finish - start
          if exception
            puts "#{ExtRake::FAILED} after #{distance_of_time total.seconds}".red
          else
            puts "#{ExtRake::COMPLETED} after #{distance_of_time total.seconds}".green
          end
        end
      end
    end

    output.dup
  end

  def skip_ouput?
    ARGV.include?('--help') \
      || name == 'environment' \
      || name.match?(/^(assets|db(?!:pg)|yarn):/) \
      || !(ENV['CRON'].to_b) \
      || Rails.env.test?
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
