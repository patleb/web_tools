require 'ext_ruby'
require 'mix_job/configuration'

module ActiveJob
  module QueueAdapters
    autoload :JobAdapter
  end
end

module MixJob
  class Engine < ::Rails::Engine
    config.before_configuration do |app|
      app.config.active_job.queue_adapter = :job
      app.config.active_record.queues.destroy = :default
      app.config.action_mailer.deliver_later_queue_name = :default
      if app.config.respond_to? :active_storage
        app.config.active_storage.queues.analysis = :default
        app.config.active_storage.queues.purge = :default
      end
      if app.config.respond_to? :action_mailbox
        app.config.action_mailbox.queues.incineration = :default
        app.config.action_mailbox.queues.routing = :default
      end
    end

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

    initializer 'mix_job.backup' do
      ExtRails.config.backup_excludes << 'lib_jobs'
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::JobAction'] = 130
    end
  end
end
