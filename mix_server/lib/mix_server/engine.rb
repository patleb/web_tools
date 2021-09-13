require 'ext_ruby'
require 'mix_server/configuration'

module MixServer
  def self.current_version
    @current_version ||= begin
      version_path = Rails.root.join('REVISION')
      version_path.exist? ? version_path.read : `git rev-parse --short HEAD`.strip
      version_path.first(7)
    end
  end

  def self.no_reboot_file
    shared_dir.join('tmp/files/no_reboot')
  end

  def self.deploy_dir
    @deploy_dir ||= "#{Rails.app}_#{Rails.env}"
  end

  def self.shared_dir
    if Rails.env.dev_or_test?
      Rails.root
    else
      Rails.root.join('..', '..', 'shared').expand_path
    end
  end

  class Engine < ::Rails::Engine
    require 'mix_server/rake/dsl'
    require 'mix_server/sh'

    config.before_initialize do
      if defined? PhusionPassenger
        PhusionPassenger.on_event(:starting_worker_process) do |_forked|
          Log.worker
        end

        PhusionPassenger.on_event(:stopping_worker_process) do
          Log.worker(stop: true)
        end
      end
    end

    initializer 'mix_server.append_migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'pgrest') if Setting[:pgrest_enabled]
    end

    initializer 'mix_server.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        # TODO
        # https://github.com/ianheggie/health_check
        # https://github.com/lbeder/health-monitor-rails
        # https://github.com/sportngin/okcomputer
        get '_information/ip' => 'servers/information#show_ip', as: :information_ip
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types.merge!(
        'LogLines::Worker' => 150,
        'LogLines::Clamav' => 160,
      )
    end
  end
end
