require "capistrano/doctor"
require "capistrano/immutable_task"

module Capistrano::DSL::Stages::Apps
  class Cap < OpenStruct
    def env
      self[:env]
    end

    def method_missing(name, *args, &block)
      if !(value = fetch(name)).nil?
        value
      elsif Setting.has_key? name
        Setting[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      !fetch(name).nil? || Setting.has_key?(name) || super
    end
  end

  def cap
    @_cap ||= Cap.new(
      env: ActiveSupport::StringInquirer.new(fetch(:stage).to_s),
      app: ActiveSupport::StringInquirer.new(fetch(:application).to_s),
      os: ActiveSupport::StringInquirer.new(fetch(:os_name).to_s),
    )
  end

  def stages
    bases = super
    bases + bases.map{ |stage| apps(stage) }.flatten
  end

  def apps(stage)
    names = Dir[app_definitions(stage)].map { |f| "#{stage}:#{File.basename(f, ".rb")}" } +
      Dir[app_definitions('applications')].map { |f| "#{stage}:#{File.basename(f, ".rb")}" }
    names.uniq!
    assert_valid_stage_names(names)
    names
  end

  def app_definitions(stage)
    stage_config_path.join(stage, "*.rb")
  end
end

extend Capistrano::DSL::Stages::Apps
include Capistrano::DSL
include Capistrano::DSL::Stages::Apps

namespace :load do
  task :defaults do
    load "capistrano/defaults.rb"

    SSHKit.config.command_map[:rake] = "bin/rake"
    SSHKit.config.command_map[:cap] = "bin/cap"
  end
end

require "airbrussh/capistrano"
# We don't need to show the "using Airbrussh" banner announcement since
# Airbrussh is now the built-in formatter. Also enable command output by
# default; hiding the output might be confusing to users new to Capistrano.
Airbrussh.configure do |airbrussh|
  airbrussh.banner = false
  airbrussh.command_output = true
end

stages.each do |stage|
  Rake::Task.define_task(stage) do
    stage, app = stage.split(':', 2)
    set(:stage, stage.to_sym)

    invoke "load:defaults"
    Rake.application["load:defaults"].extend(Capistrano::ImmutableTask)
    env.variables.untrusted! do
      load deploy_config_path
      load stage_config_path.join("#{stage}.rb")
      if app
        set(:application, app)
        app_config_path = stage_config_path.join('applications', "#{app}.rb")
        load app_config_path if File.exist?(app_config_path)
        stage_app_config_path = stage_config_path.join(stage, "#{app}.rb")
        load stage_app_config_path if File.exist?(stage_app_config_path)
      end

      Setting.load(env: stage, app: app)

      # TODO deploy DB server behind proxy server
      # https://www.randomerrata.com/articles/2015/deploying-via-a-bastion-host-with-capistrano-3/
      if Setting[:server_cluster]
        Cloud.server_cluster_ips.each do |server|
          server server, user: fetch(:deployer_name), roles: %i(web app)
        end
      else
        server fetch(:server), user: fetch(:deployer_name), roles: %i(web app)
      end
    end
    configure_scm
    I18n.locale = fetch(:locale, :en)
    configure_backend
  end
end

require "capistrano/dotfile"
