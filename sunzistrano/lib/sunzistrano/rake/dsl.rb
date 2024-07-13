module Rake
  module DSL
    def sun_rake(task_string, env: Rails.env, app: Rails.app, host: nil)
      no_color = 'DISABLE_COLORIZATION=true' if ENV['DISABLE_COLORIZATION'].to_b
      host = "--host=#{host}" if host.present?
      task = [task_string, no_color].compact.join(' ')
      sh "bin/sun rake #{[env, app].compact.join('-')} '#{task.escape_single_quotes}' #{host}"
    end
  end
end
