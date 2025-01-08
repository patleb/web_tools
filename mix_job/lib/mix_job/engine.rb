require 'mix_server'
require 'mix_job/configuration'
require 'mix_job/routes'

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
        queues = app.config.active_storage.queues
        queues.analysis = queues.mirror = queues.purge = queues.transform = :default
      end
      if app.config.respond_to? :action_mailbox
        app.config.action_mailbox.queues.incineration = app.config.action_mailbox.queues.routing = :default
      end
    end

    initializer 'mix_job.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_job.http_status_codes' do
      Rack::Utils.add_status_code(460, "Job Client Error")
      Rack::Utils.add_status_code(540, "Job Server Error")

      require 'mix_job/http/response/status'
    end

    initializer 'mix_job.routes', before: 'ext_rails.routes' do |app|
      app.routes.prepend do
        MixJob::Routes.draw(self)
      end
    end

    initializer 'mix_job.backup' do
      ExtRails.config.temporary_tables << 'lib_jobs'
    end

    config.after_initialize do |app|
      MonkeyPatch.add{[__FILE__, app.config.active_record.queues.keys.sort, [:destroy]]}
      MonkeyPatch.add{[__FILE__, app.config.active_storage.queues.keys.sort, [:analysis, :mirror, :purge, :transform]]} if app.config.respond_to? :active_storage
      MonkeyPatch.add{[__FILE__, app.config.action_mailbox.queues.keys.sort, [:incineration, :routing]]} if app.config.respond_to? :action_mailbox
    end

    ActiveSupport.on_load(:active_record) do
      MixServer::Log.config.available_types['LogLines::JobAction'] = MixServer::Log::DB_TYPE + 60
    end
  end
end
