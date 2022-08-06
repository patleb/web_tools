module Rake
  module DSL
    def run_ftp_list(match, **options)
      `#{Sh.ftp_list(match, **options)}`.lines.map(&:strip).map(&:split).map do |columns|
        if columns.size == 3
          { size: columns[0].to_i, time: Time.parse(columns[1]), name: columns[2] }.with_keyword_access
        else
          { time: Time.parse(columns[0]), name: columns[1].delete_suffix('/') }.with_keyword_access
        end
      end
    end
    module_function :run_ftp_list

    def run_ftp_cat(match, **options)
      `#{Sh.ftp_cat(match, **options)}`.strip
    end
    module_function :run_ftp_cat

    def cap
      OpenStruct.new(env: Setting.env, app: Setting.app, os: Process.os.to_s)
    end

    def fetch(name)
      raise "Setting.env == '#{Setting.env}'" unless Setting.env != 'development'

      @capistrano ||= Sunzistrano::Context.capistrano(Setting.stage).with_keyword_access

      Setting.with(env: Setting.env, app: Setting.app) do |all|
        @capistrano.merge(all)[name]
      end
    end
  end
end
