# frozen_string_literal: true

module Sunzistrano
  class Context < OpenStruct
    VARIABLES = /__([A-Z0-9_]+)__/

    attr_reader :gems

    def self.root
      Pathname.new(Dir.pwd)
    end

    def initialize(stage, role, root: self.class.root, **options)
      validate_config_presence! root
      @env, @app = stage.split(':', 2)
      Setting.with(env: @env, app: @app, root: root) do |settings|
        @app ||= Setting.default_app
        @role = role
        @gems = {}
        context = settings.merge(extract_yml(root))
        context.merge! options
        require_overrides
        @replaced&.each{ |key| context[key.delete_suffix(Hash::REPLACE)] = context.delete(key) }
        remove_instance_variable(:@replaced) if instance_variable_defined? :@replaced
        super(context)
      end
    end

    def attributes
      to_h.reject{ |_, v| (v != false && v.blank?) || v.is_a?(Hash) || v.is_a?(Array) || v.to_s.match?(/(\s|<%.+%>)/) }.merge(
        role: role,
        env: env,
        app: app,
        os_name: os,
        owner_public_key: owner_public_key,
        owner_private_key: owner_private_key&.escape_newlines,
        bash_log: Sunzistrano::BASH_LOG,
        bash_dir: Sunzistrano::BASH_DIR,
        manifest_log: Sunzistrano::MANIFEST_LOG,
        manifest_dir: Sunzistrano::MANIFEST_DIR,
        metadata_dir: Sunzistrano::METADATA_DIR,
        defaults_dir: Sunzistrano::DEFAULTS_DIR,
      )
    end

    def servers
      @servers ||= server_cluster ? Cloud.server_cluster_ips : [server]
    end

    def server_cluster?
      server_cluster
    end

    def owner_public_key
      self[:owner_public_key].presence && "'#{self[:owner_public_key]}'"
    end

    def owner_private_key
      self[:owner_private_key].presence && "'#{self[:owner_private_key]}'"
    end

    def role
      @_role ||= ActiveSupport::StringInquirer.new(@role.to_s)
    end

    def env
      @_env ||= ActiveSupport::StringInquirer.new(@env.to_s)
    end

    def app
      @_app ||= ActiveSupport::StringInquirer.new(@app.to_s)
    end

    def os
      @_os ||= ActiveSupport::StringInquirer.new(os_name || 'ubuntu')
    end

    def helpers(root)
      base_dir = Pathname.new(root).join(Sunzistrano::CONFIG_PATH, 'helpers')
      Dir[base_dir.join('**/*.sh').to_s].map do |file|
        Pathname.new(file).relative_path_from(base_dir).to_s
      end
    end

    def role_recipes(*names)
      recipes = merge_recipes names
      if (reboot = recipes.delete('reboot'))
        recipes << reboot
      end
      if recipe.present?
        recipes.select! do |name|
          name == recipe
        end
      end
      recipes.each do |name|
        yield name, gsub_variables(name) unless name.blank?
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

    def merge_recipes(names)
      (recipes || []).each_with_object(names.reject(&:blank?)) do |recipe, memo|
        next memo << recipe if recipe.is_a? String
        recipe, action = recipe.first
        action, sibling = action&.first
        case action
        when 'remove'
          memo.delete(recipe)
        when 'before'
          memo.insert_before(sibling, recipe)
        when 'after'
          memo.insert_after(sibling, recipe)
        else
          memo << recipe
        end
      end
    end

    def extract_yml(root)
      path = root.join(Sunzistrano::CONFIG_YML)
      return {} unless path.exist?

      yml = YAML.safe_load(ERB.new(path.read).result(binding))
      validate_version! yml['lock']
      gems_yml = (yml['gems'] || []).reduce({}) do |gems_yml, name|
        if @gems.has_key? name
          gems_yml
        else
          gems_yml.union! extract_yml(gem_root(name))
        end
      end
      role_yml = (yml['shared'] || {}).union!(yml[@role] || {})
      env_yml = (yml[@env] || {})
      env_yml.union!(yml["#{@env}_#{@role}"] || {})
      role_yml.union!(env_yml)
      if @app
        app_yml = (yml[@app] || {})
        app_yml.union!(yml["#{@app}_#{@role}"] || {})
        app_yml.union!(yml["#{@app}_#{@env}"] || {})
        app_yml.union!(yml["#{@app}_#{@env}_#{@role}"] || {})
        role_yml.union!(app_yml)
      end
      yml = (gems_yml || {}).union!(role_yml)
      yml.each_key do |key|
        if key.end_with? Hash::REPLACE
          (@replaced ||= Set.new) << key
        end
      end
      yml
    end

    def gem_root(name)
      @gems[name] ||= Gem.root(name) or raise "gem [#{name}] not found"
    end

    def require_overrides
      @gems.each_key do |name|
        require "#{name}/sunzistrano" if File.exist? "#{name}/sunzistrano.rb"
      end
      require 'app/libraries/sunzistrano' if File.exist? 'app/libraries/sunzistrano.rb'
    end

    def validate_version!(lock)
      unless lock.nil? || lock == Sunzistrano::VERSION
        raise "Sunzistrano version [#{Sunzistrano::VERSION}] is different from locked version [#{lock}]"
      end
    end

    def validate_config_presence!(root)
      raise 'You must have a sunzistrano.yml' unless root.join(Sunzistrano::CONFIG_YML).exist?
    end
  end
end
