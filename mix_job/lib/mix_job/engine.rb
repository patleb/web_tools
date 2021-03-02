require 'ext_ruby'
require 'mix_job/configuration'

module ActiveJob
  module QueueAdapters
    autoload :JobAdapter
  end
end

module MixJob
  class Engine < ::Rails::Engine
    config.before_initialize do
      autoload_models_if_admin('Job')
    end

    initializer 'mix_job.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_job.http_status_codes' do
      Rack::Utils.add_status_code(460, "Job Client Error")
      Rack::Utils.add_status_code(540, "Job Server Error")

      require 'mix_job/http/response/status'
    end

    initializer 'mix_job.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        post '/_jobs/:job_class/:job_id' => 'jobs#create', as: :jobs
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::JobWatchAction'] = 130
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mix_job/action_mailer/base'
    end
  end
end
