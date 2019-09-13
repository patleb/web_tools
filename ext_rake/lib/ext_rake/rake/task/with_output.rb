class RakeError < RescueError
  def self.rescue_class
    RakeRescue
  end
end

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
          puts "#{ExtRake::STARTED}[#{Process.pid}] #{name}".blue
          super
        rescue Exception => exception
          data = { name => args&.to_h, host: Process.host.snapshot }
          Notice.new.deliver! RakeError.new(exception, data), subject: name do |message|
            puts message
          end
        ensure
          puts "[#{start}]#{ExtRake::TASK}[#{Process.pid}]" if output.exclude? ExtRake::STEP
          finish = Time.current.utc
          puts "[#{finish}]#{ExtRake::DONE}[#{Process.pid}]"
          total = finish - start
          if exception
            puts "#{ExtRake::FAILED}[#{Process.pid}] after #{distance_of_time total.seconds}".red
          else
            puts "#{ExtRake::COMPLETED}[#{Process.pid}] after #{distance_of_time total.seconds}".green
          end
        end
      end
    end

    output.dup
  end

  def skip_ouput?
    ARGV.include?('--help') || name == 'environment' || !(ENV['RAKE_OUTPUT'].to_b)
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
