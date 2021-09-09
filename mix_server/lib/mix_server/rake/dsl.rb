module Rake
  module DSL
    def nginx_maintenance_message(duration = nil)
      time =
        case duration
        when /\d+\.weeks?$/   then duration.to_i.weeks.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
        when /\d+\.days?$/    then duration.to_i.day.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
        when /\d+\.hours?$/   then duration.to_i.hours.from_now.to_s.sub(/\d{2}:\d{2} UTC$/, '00:00 UTC')
        when /\d+\.minutes?$/ then duration.to_i.minutes.from_now.to_s.sub(/\d{2} UTC$/, '00 UTC')
        when /\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}/ then "#{duration} UTC"
        when nil
        else
          raise 'invalid :duration'
        end
      "Should be back around #{time}".gsub(' ', '&nbsp;').gsub('-', '&#8209;') if time
    end
    module_function :nginx_maintenance_message

    def run_ftp_list(match, **options)
      `#{Sh.ftp_list(match, **options)}`.lines.map(&:strip).map(&:split).map do |columns|
        if columns.size == 3
          { size: columns[0].to_i, time: Time.parse(columns[1]), name: columns[2] }.with_keyword_access
        else
          { time: Time.parse(columns[0]), name: columns[1].delete_suffix('/') }.with_keyword_access
        end
      end
    end

    def run_ftp_cat(match, **options)
      `#{Sh.ftp_cat(match, **options)}`.strip
    end

    def cap
      OpenStruct.new(env: Setting.rails_env, app: Setting.rails_app, os: Process.os.to_s)
    end

    def fetch(name)
      raise "Setting.rails_env == '#{Setting.rails_env}'" unless Setting.rails_env != 'development'

      @capistrano ||= Sunzistrano::Context.capistrano(Setting.rails_stage).with_keyword_access

      Setting.with(env: Setting.rails_env, app: Setting.rails_app) do |all|
        @capistrano.merge(all)[name]
      end
    end
  end
end
