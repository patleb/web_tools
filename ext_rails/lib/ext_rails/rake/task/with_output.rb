module Rake::Task::WithOutput
  extend ActiveSupport::Concern

  prepended do
    include ActionView::Helpers::DateHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::NumberHelper
  end

  def puts_started(args)
    puts "[#{Time.current.utc}]#{Rake::STARTED}[#{Process.pid}] #{name}".cyan
  end

  def puts_success(total)
    puts "[#{Time.current.utc}]#{Rake::SUCCESS}[#{Process.pid}] #{name} -- : #{distance_of_time total}".green
  end

  def puts_failure(exception)
    puts "[#{Time.current.utc}]#{Rake::FAILURE}[#{Process.pid}] #{name}".red
  end

  def puts_downloading(file_name, remainder, total)
    remainder = number_to_human_size remainder
    total = number_to_human_size total
    puts "Downloading #{file_name}[#{Process.pid}][#{total}] remaining #{remainder}"
  end

  def execute(args = nil)
    old_disable_colorization = String.try(:disable_colorization)
    String.try(:disable_colorization=, true) if ENV['NO_COLOR'].to_b
    unless rake_ouput?
      if ENV['RAKE_PROFILE']
        require 'ext_rails/lineprof'
        result = nil
        Lineprof.profile(%r{#{ENV['RAKE_PROFILE']}}) do
          result = super
        end
        return result
      else
        return with_db_loggers{ super }
      end
    end

    started_at = Concurrent.monotonic_time
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
  ensure
    String.try(:disable_colorization=, old_disable_colorization)
  end

  def rake_ouput?
    ARGV.exclude?('--help') && name != 'environment' && ENV['RAKE_OUTPUT'].to_b
  end

  def with_db_loggers
    if ExtRails.config.sql_debug
      @_ar_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = ::Logger.new(STDOUT)
    end
    yield
  ensure
    if ExtRails.config.sql_debug
      ActiveRecord::Base.logger = @_ar_logger
    end
  end
end

Rake::Task.prepend Rake::Task::WithOutput
