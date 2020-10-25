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
          puts_started name
          super
        rescue Exception => exception
          unless Thread.current[:rake_error]
            Thread.current[:rake_error] = true
            data = { name => args&.to_h, host: Process.host.snapshot }
            Notice.deliver! Rescues::RakeError.new(exception, data), subject: name
          end
          raise
        ensure
          puts_task start if output.exclude? ExtRake::STEP
          finish = Time.current.utc
          puts_done finish
          total = finish - start
          if exception
            puts_failed total
          else
            puts_completed total
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

  def puts_started(name)
    puts "#{ExtRake::STARTED}[#{Process.pid}] #{name}".blue
  end

  def puts_task(start_time)
    puts "[#{start_time}]#{ExtRake::TASK}[#{Process.pid}]"
  end

  def puts_done(finish_time)
    puts "[#{finish_time}]#{ExtRake::DONE}[#{Process.pid}]"
  end

  def puts_completed(total_time)
    puts "#{ExtRake::COMPLETED}[#{Process.pid}] after #{distance_of_time total_time.seconds}".green
  end

  def puts_failed(total_time)
    puts "#{ExtRake::FAILED}[#{Process.pid}] after #{distance_of_time total_time.seconds}".red
  end
end
