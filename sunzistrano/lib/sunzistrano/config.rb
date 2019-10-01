# frozen_string_literal: true

module Sunzistrano
  class Config < OpenStruct
    RESERVED_NAMES = %w(lock gems debug sudo reboot)
    VARIABLES = /__([A-Z0-9_]+)__/
    PROVISION_LOG = 'sun_provision.log'
    PROVISION_DIR = 'sun_provision'
    MANIFEST_LOG = 'sun_manifest.log'
    MANIFEST_DIR = 'sun_manifest'
    DEFAULTS_DIR = 'sun_defaults'

    constants.each do |name|
      define_method name do
        self.class.const_get name
      end
    end

    def self.provision_yml
      Pathname.new(File.expand_path('config/provision.yml'))
    end

    def initialize(stage, role, options)
      env, app = stage.split(':', 2)
      settings = { stage: env, application: app }.with_indifferent_access
      settings.merge! Capistrano.config(stage) if Gem.loaded_specs['sun_cap']
      @stage, @application, root = settings.values_at(:stage, :application, :root)
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

      settings.merge! Setting.load(env: @stage, app: @application, root: root || ENV['RAILS_ROOT'] || '') if Gem.loaded_specs['mr_setting']
      settings.union!(role_yml).merge!(role: @role).merge!(options).merge!(yml.slice(*RESERVED_NAMES))
      settings.each_key do |key|
        settings[key.delete_suffix(Hash::REPLACE)] = settings.delete(key) if key.end_with? Hash::REPLACE
      end
      super(settings)
    end

    def attributes
      to_h.reject{ |_, v| v.nil? || v.is_a?(Hash) || v.is_a?(Array) || v.to_s.match?(/(\s|<%.+%>)/) }.merge(
        linux_os: os,
        username: username,
        admin_public_key: ->{ admin_public_key },
        admin_private_key: ->{ admin_private_key.escape_newlines },
        provision_log: PROVISION_LOG,
        provision_dir: PROVISION_DIR,
        manifest_log: MANIFEST_LOG,
        manifest_dir: MANIFEST_DIR,
        defaults_dir: DEFAULTS_DIR,
      )
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
      @_os ||= ActiveSupport::StringInquirer.new(linux_os || 'ubuntu')
    end

    def local_dir
      if local_path.present?
        @_local_dir ||= Pathname.new(local_path).expand_path
      end
    end

    def admin_public_key
      if (key = self[:admin_public_key] || `ssh-keygen -f #{pkey} -y`.strip).present?
        "'#{key}'"
      end
    end

    def admin_private_key
      if (key = self[:admin_private_key] || `cat #{pkey}`.strip).present?
        "'#{key}'"
      end
    end

    def pkey
      @_pkey ||=
        if env.vagrant?
          `vagrant ssh-config #{vagrant_name}`.split("\n").drop(1).map(&:strip).each_with_object({}){ |key_value, configs|
            key, value = key_value.split(' ', 2)
            configs[key.underscore] = value
          }['identity_file']
        else
          self[:pkey]
        end
    end

    def list_helpers(root)
      base_dir = Pathname.new(root).join('config/provision/helpers')
      Dir[base_dir.join('**/*.sh').to_s].map do |file|
        Pathname.new(file).relative_path_from(base_dir).to_s
      end
    end

    def role_recipes(*names)
      recipes = _merge_recipes names
      if (reboot = recipes.delete('reboot'))
        recipes << reboot
      end
      list_recipes(recipes) do |name, id|
        yield name, id
      end
    end

    def list_recipes(*names, base: nil)
      recipes = _merge_recipes *names, base, substract: true
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

    def _merge_recipes(names, base = nil, substract: false)
      recipes = Array.wrap(names).reject(&:blank?)
      if base
        recipes.map!{ |name| "#{base}/#{name}" }
      end
      if substract
        recipes - (skip_recipes || []).reject(&:blank?)
      else
        recipes + (add_recipes || []).reject(&:blank?)
      end
    end
  end
end
