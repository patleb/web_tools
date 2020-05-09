# frozen_string_literal: true

module Sunzistrano
  class Context < OpenStruct
    RESERVED_NAMES = %w(lock gems debug sudo reboot)
    VARIABLES = /__([A-Z0-9_]+)__/
    PROVISION_LOG = 'sun_provision.log'
    PROVISION_DIR = 'sun_provision'
    MANIFEST_LOG = 'sun_manifest.log'
    MANIFEST_DIR = 'sun_manifest'
    METADATA_DIR = 'sun_metadata'
    DEFAULTS_DIR = 'sun_defaults'

    def self.provision_yml
      Pathname.new(File.expand_path('config/provision.yml'))
    end

    def initialize(stage, role, options)
      env, app = stage.split(':', 2)
      settings = { stage: env, application: app }.with_indifferent_access
      settings.merge! capistrano(stage)
      @stage, @application = settings.values_at(:stage, :application)
      @role = role

      yml = YAML.safe_load(ERB.new(self.class.provision_yml.read).result(binding))
      role_yml = (yml['shared'] || {}).union!(yml[@role] || {})
      env_yml = (yml[@stage] || {})
      env_yml.union!(yml["#{@stage}_#{@role}"] || {})
      role_yml.union!(env_yml)
      if @application
        app_yml = (yml[@application] || {})
        app_yml.union!(yml["#{@application}_#{@role}"] || {})
        app_yml.union!(yml["#{@application}_#{@stage}"] || {})
        app_yml.union!(yml["#{@application}_#{@stage}_#{@role}"] || {})
        role_yml.union!(app_yml)
      end

      settings.merge! Setting.load(env: @stage, app: @application)
      settings.union!(role_yml).merge!(role: @role).merge!(options).merge!(yml.slice(*RESERVED_NAMES))
      settings.each_key do |key|
        settings[key.delete_suffix(Hash::REPLACE)] = settings.delete(key) if key.end_with? Hash::REPLACE
      end
      super(settings)
    end

    def attributes
      to_h.reject{ |_, v| v.nil? || v.is_a?(Hash) || v.is_a?(Array) || v.to_s.match?(/(\s|<%.+%>)/) }.merge(
        os_name: os,
        username: username,
        admin_public_key: admin_public_key,
        admin_private_key: admin_private_key.escape_newlines,
        provision_log: PROVISION_LOG,
        provision_dir: PROVISION_DIR,
        manifest_log: MANIFEST_LOG,
        manifest_dir: MANIFEST_DIR,
        metadata_dir: METADATA_DIR,
        defaults_dir: DEFAULTS_DIR,
      )
    end

    def servers
      @servers ||= server_cluster ? Cloud.server_cluster_ips : [server]
    end

    def server_cluster?
      server_cluster
    end

    def admin_public_key
      self[:admin_public_key].presence && "'#{self[:admin_public_key]}'"
    end

    def admin_private_key
      self[:admin_private_key].presence && "'#{self[:admin_private_key]}'"
    end

    def username
      if (value = self[:username]).present?
        value
      else
        sudo ? admin_name : deployer_name
      end
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(stage.to_s)
    end

    def app
      @_app ||= ActiveSupport::StringInquirer.new(application.to_s)
    end

    def os
      @_os ||= ActiveSupport::StringInquirer.new(os_name || 'ubuntu')
    end

    def local_dir
      if local_path.present?
        @_local_dir ||= Pathname.new(local_path).expand_path
      end
    end

    def list_helpers(root)
      base_dir = Pathname.new(root).join('config/provision/helpers')
      Dir[base_dir.join('**/*.sh').to_s].map do |file|
        Pathname.new(file).relative_path_from(base_dir).to_s
      end
    end

    def role_recipes(*names)
      recipes = merge_recipes names
      if (reboot = recipes.delete('reboot'))
        recipes << reboot
      end
      list_recipes(recipes) do |name, id|
        yield name, id
      end
    end

    def list_recipes(*names, base: nil)
      recipes = merge_recipes *names, base, substract: true
      if recipe.present?
        recipes.select! do |name|
          name.end_with?("/all") || name == recipe
        end
      end
      recipes.reject(&:blank?).each do |name|
        yield name, gsub_variables(name)
      end
    end

    def gsub_variables(name)
      has_variables = false
      segments = name.gsub(VARIABLES) do |segment|
        has_variables = true
        segment.gsub!(/(^__|__$)/, '').downcase!
        (value = try(segment)) ? "-#{value}" : ''
      end
      "'#{segments}'" if has_variables
    end

    private

    def merge_recipes(names, base = nil, substract: false)
      recipes = Array.wrap(names).reject(&:blank?)
      if base
        recipes.map!{ |name| "#{base}/#{name}" }
      end
      if substract
        recipes - (remove_recipes || []).reject(&:blank?)
      else
        recipes + (append_recipes || []).reject(&:blank?)
      end
    end

    def capistrano(stage)
      cap = File.file?('bin/cap') ? 'bin/cap' : 'bundle exec cap'
      stdout, stderr, status = Open3.capture3("#{cap} #{stage} sunzistrano:capistrano --dry-run")
      if status.success?
        if stdout.present?
          stdout.lines.each_with_object({}) do |key_value, memo|
            key, value = key_value.strip.split(' ', 2).map(&:strip)
            memo[key] = value unless value.blank? || key == 'DEBUG'
          end
        else
          puts %{cap #{stage} sunzistrano:capistrano => ""}.red
          {}
        end
      else
        puts stderr.red
        {}
      end
    end
  end
end
